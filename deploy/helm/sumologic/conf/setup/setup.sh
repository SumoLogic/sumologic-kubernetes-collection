#!/bin/bash

readonly DEBUG_MODE=${DEBUG_MODE:="false"}
readonly DEBUG_MODE_ENABLED_FLAG="true"
readonly SUMOLOGIC_COLLECTOR_NAME="${SUMOLOGIC_COLLECTOR_NAME:?}"
readonly NAMESPACE="${NAMESPACE:?}"
readonly SUMOLOGIC_SECRET_NAME="${SUMOLOGIC_SECRET_NAME:?}"

# Set variables for terraform
export TF_VAR_collector_name="${SUMOLOGIC_COLLECTOR_NAME}"
export TF_VAR_namespace_name="${NAMESPACE}"
export TF_VAR_secret_name="${SUMOLOGIC_SECRET_NAME}"
export TF_VAR_chart_version="${CHART_VERSION:?}"
export TF_VAR_use_extension="${SUMOLOGIC_USE_EXTENSION:-false}"
export TF_VAR_extension_secret_name="${SUMOLOGIC_EXTENSION_SECRET_NAME:-sumologic-extension}"
export TF_VAR_provided_installation_token="${SUMOLOGIC_INSTALLATION_TOKEN:+true}"
export TF_VAR_provided_installation_token="${TF_VAR_provided_installation_token:-false}"

# Let's compare the variables ignoring the case with help of ${VARIABLE,,} which makes the string lowercased
# so that we don't have to deal with True vs true vs TRUE
if [[ ${DEBUG_MODE,,} == "${DEBUG_MODE_ENABLED_FLAG}" ]]; then
    echo "Entering the debug mode with continuous sleep. No setup will be performed."
    echo "Please exec into the setup container and run the setup.sh by hand or set the sumologic.setup.debug=false and reinstall."

    while true; do
        sleep 10
        DATE=$(date)
        echo "${DATE} Sleeping in the debug mode..."
    done
fi

# Apply CRDs if command provided as argument
if [[ -n "${1:-}" ]]; then
    echo "Applying CRDs with command: $1"
    eval "$1"
fi

function fix_sumo_base_url() {
  local BASE_URL
  BASE_URL=${SUMOLOGIC_BASE_URL}

  if [[ "${BASE_URL}" =~ ^\s*$ ]]; then
    BASE_URL="https://api.sumologic.com/api/"
  fi

  # shellcheck disable=SC2312
  OPTIONAL_REDIRECTION="$(curl -XGET -s -o /dev/null -D - \
          -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
          "${BASE_URL}"v1/collectors \
          | grep -Fi location )"

  if [[ ! ${OPTIONAL_REDIRECTION} =~ ^\s*$ ]]; then
    BASE_URL=$( echo "${OPTIONAL_REDIRECTION}" | sed -E 's/.*: (https:\/\/.*(au|ca|de|eu|fed|in|jp|kr|ch|esc|us2)?\.sumologic\.com\/api\/).*/\1/' )
  fi

  BASE_URL=${BASE_URL%v1*}

  echo "${BASE_URL}"
}

SUMOLOGIC_BASE_URL=$(fix_sumo_base_url)
export SUMOLOGIC_BASE_URL
# Support proxy for Terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

function get_remaining_fields() {
    local RESPONSE
    RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields/quota)"
    readonly RESPONSE

    echo "${RESPONSE}"
}

# Check if we'd have at least 10 fields remaining after additional fields
# would be created for the collection
function should_create_fields() {
    local RESPONSE
    RESPONSE=$(get_remaining_fields)
    readonly RESPONSE

    if ! jq -e <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        return 1
    fi

    if ! jq -e '.remaining' <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        return 1
    fi

    local REMAINING
    REMAINING=$(jq -e '.remaining' <<< "${RESPONSE}")
    readonly REMAINING
    if [[ $(( REMAINING - ${#FIELDS} )) -ge 10 ]] ; then
        return 0
    else
        return 1
    fi
}

cp /etc/terraform/* /terraform/
cd /terraform || exit 1

FIELDS_STRING=$(jq -r '.fields[]' terraform.tfvars.json)
mapfile -t FIELDS < <(echo "${FIELDS_STRING}")

# Remove lock file to prevent version conflicts on upgrades
if [[ -f .terraform.lock.hcl ]]; then
    echo "Removing existing Terraform lock file to prevent provider version conflicts"
    rm -f .terraform.lock.hcl
fi

# Run pre-init script if provided (for downloading providers, etc.)
if [[ -f /customer-scripts/terraform_pre-init.sh ]]; then
    echo "===================================================================="
    echo "Running pre-init script: /customer-scripts/terraform_pre-init.sh"
    echo "===================================================================="
    if ! bash /customer-scripts/terraform_pre-init.sh; then
        echo "ERROR: Pre-init script failed with exit code $?"
        echo "Cannot proceed with Terraform setup due to pre-initialization failure."
        exit 1
    fi
    echo "Pre-init script completed successfully"
fi

# Check for custom Terraform CLI config file (for internal registry support)
if [[ -f /customer-scripts/terraform_terraformrc ]]; then
    export TF_CLI_CONFIG_FILE=/customer-scripts/terraform_terraformrc
    echo "===================================================================="
    echo "Using custom Terraform CLI config: ${TF_CLI_CONFIG_FILE}"
    echo "Providers will be downloaded from internal registry as configured."
    echo "===================================================================="
fi

# Initialize Terraform with upgrade to handle provider version changes
terraform init -input=false -upgrade || {
    echo "Terraform init failed, attempting to clean .terraform directory"
    rm -rf .terraform
    terraform init -input=false -upgrade
}

# Sumo Logic fields
if should_create_fields ; then
    readonly CREATE_FIELDS=1
    # shellcheck disable=SC2312
    FIELDS_RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields | jq '.data[]' )"
    readonly FIELDS_RESPONSE

    for FIELD in "${FIELDS[@]}" ; do
        FIELD_ID=$( echo "${FIELDS_RESPONSE}" | jq -r "select(.fieldName | ascii_downcase == \"${FIELD}\") | .fieldId" )
        # Don't try to import non existing fields
        if [[ -z "${FIELD_ID}" ]]; then
            continue
        fi

        terraform import \
            -var="create_fields=1" \
            sumologic_field.collection_field[\""${FIELD}"\"] "${FIELD_ID}"
    done
else
    readonly CREATE_FIELDS=0
    echo "Couldn't automatically create fields"
    echo "You do not have enough field capacity to create the required fields automatically."
    echo "Please refer to https://www.sumologic.com/help/docs/manage/fields/ to manually create the fields after you have removed unused fields to free up capacity."
fi

# Delete hosted collector (and all its sources) via API when cleanup is requested.
# Terraform cannot destroy resources it cannot import, so we use the API directly.
function delete_hosted_collector() {
    local RESPONSE COLLECTOR_ID
    RESPONSE="$(curl -XGET -s --retry 3 --retry-delay 5 \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}v1/collectors?filter=hosted&limit=1000" || echo "{}")"
    local JQ_OUTPUT
    JQ_OUTPUT=$(jq -r ".collectors[]? | select(.name == \"${SUMOLOGIC_COLLECTOR_NAME}\") | .id" <<< "${RESPONSE}")
    COLLECTOR_ID=$(head -1 <<< "${JQ_OUTPUT}")
    if [[ -n "${COLLECTOR_ID}" ]]; then
        echo "Deleting hosted collector '${SUMOLOGIC_COLLECTOR_NAME}' (${COLLECTOR_ID}) and all its sources..."
        local DELETE_RESPONSE
        DELETE_RESPONSE="$(curl -s -XDELETE \
            -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
            -w "\n%{http_code}" \
            "${SUMOLOGIC_BASE_URL}v1/collectors/${COLLECTOR_ID}")"
        local HTTP_CODE DELETE_BODY
        HTTP_CODE=$(tail -1 <<< "${DELETE_RESPONSE}")
        DELETE_BODY=$(head -1 <<< "${DELETE_RESPONSE}")
        if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "204" ]]; then
            echo "Hosted collector deleted."
        else
            echo "Failed to delete hosted collector '${SUMOLOGIC_COLLECTOR_NAME}' (${COLLECTOR_ID}). HTTP ${HTTP_CODE}: ${DELETE_BODY}"
            return 1
        fi
    else
        echo "Hosted collector '${SUMOLOGIC_COLLECTOR_NAME}' not found, nothing to delete."
    fi
}

if [[ "${SUMOLOGIC_USE_EXTENSION:-false}" == "true" && "${SUMOLOGIC_CLEANUP_HOSTED_COLLECTOR:-false}" == "true" ]]; then
    delete_hosted_collector
fi

# Sumo Logic Collector and HTTP sources
# In extension mode the collector is not managed by Terraform (count=0), so skip import entirely.
if [[ "${SUMOLOGIC_USE_EXTENSION:-false}" != "true" ]]; then
    # Only import sources when collector exists.
    if terraform import 'sumologic_collector.collector[0]' "${SUMOLOGIC_COLLECTOR_NAME}"; then
        jq -r '.resource[] | to_entries[] | "\(.key) \(.value.name)"' sources.tf.json | while read -r resource_name source_name; do
            terraform import "sumologic_http_source.${resource_name}" "${SUMOLOGIC_COLLECTOR_NAME}/${source_name}"
        done || true
    fi
fi

# Import existing installation token if extension mode is enabled (prevents recreation on upgrades)
function import_installation_token() {
    local TOKEN_NAME="kubernetes-collection-${SUMOLOGIC_COLLECTOR_NAME}"
    local RESPONSE TOKEN_ID
    RESPONSE="$(curl -XGET -s --retry 3 --retry-delay 5 \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}v1/tokens?limit=1000" || echo "{}")"
    local JQ_OUTPUT
    if ! jq -e '.data' <<< "${RESPONSE}" > /dev/null 2>&1; then
        echo "WARNING: Token API response does not contain .data — skipping token import."
        return 0
    fi
    JQ_OUTPUT=$(jq -r ".data[]? | select(.name == \"${TOKEN_NAME}\") | .id" <<< "${RESPONSE}")
    TOKEN_ID=$(head -1 <<< "${JQ_OUTPUT}")
    if [[ -n "${TOKEN_ID}" ]]; then
        echo "Importing existing installation token: ${TOKEN_NAME} (${TOKEN_ID})"
        terraform import \
            -var="use_extension=true" \
            'sumologic_token.collection_token[0]' "${TOKEN_ID}" || echo "WARNING: failed to import sumologic_token.collection_token[0] (${TOKEN_ID})"
    fi
}

# Import existing token only when extension mode is on AND Terraform manages it (no user-provided token).
if [[ "${SUMOLOGIC_USE_EXTENSION:-false}" == "true" && "${TF_VAR_provided_installation_token}" != "true" ]]; then
    import_installation_token
fi

# Kubernetes Secrets
if [[ "${SUMOLOGIC_USE_EXTENSION:-false}" != "true" ]]; then
    terraform import "kubernetes_secret.sumologic_collection_secret[0]" "${NAMESPACE}/${SUMOLOGIC_SECRET_NAME}" || true
elif [[ "${TF_VAR_provided_installation_token}" != "true" ]]; then
    # Extension mode with Terraform-managed token: import the extension secret when token is not provided via values.
    terraform import "kubernetes_secret.extension_secret[0]" "${NAMESPACE}/${TF_VAR_extension_secret_name}" || true
fi

# Apply planned changes
TF_LOG_PROVIDER=DEBUG terraform apply \
    -auto-approve \
    -var="create_fields=${CREATE_FIELDS}" \
    || { echo "Error during applying Terraform changes"; exit 1; }

# Delete sources that exist on the collector but are not in the current config.
# This cleans up sources that became unused after sourceType changes.
function cleanup_unused_sources() {
    echo "Checking for unused sources to clean up..."

    # Get expected source names from the current config
    local EXPECTED_SOURCES
    EXPECTED_SOURCES=$(jq -r '.resource.sumologic_http_source | to_entries[] | .value.name' sources.tf.json 2>/dev/null)
    if [[ -z "${EXPECTED_SOURCES}" ]]; then
        echo "No sources in config, skipping cleanup."
        return
    fi

    # Get collector ID by looking up the collector
    local COLLECTOR_RESPONSE
    COLLECTOR_RESPONSE=$(curl -s -G \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        --data-urlencode "filter=${SUMOLOGIC_COLLECTOR_NAME}" \
        "${SUMOLOGIC_BASE_URL}v1/collectors")

    local COLLECTOR_ID
    COLLECTOR_ID=$(echo "${COLLECTOR_RESPONSE}" | jq -r ".collectors[] | select(.name == \"${SUMOLOGIC_COLLECTOR_NAME}\") | .id")
    if [[ -z "${COLLECTOR_ID}" || "${COLLECTOR_ID}" == "null" ]]; then
        echo "Could not find collector ID, skipping source cleanup."
        return
    fi

    # List all existing sources on the collector
    local SOURCES_RESPONSE
    SOURCES_RESPONSE=$(curl -s -XGET \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}v1/collectors/${COLLECTOR_ID}/sources")

    local EXISTING_SOURCES
    EXISTING_SOURCES=$(echo "${SOURCES_RESPONSE}" | jq -r '.sources[] | "\(.id)\t\(.name)"')
    if [[ -z "${EXISTING_SOURCES}" ]]; then
        echo "No existing sources found on collector, skipping cleanup."
        return
    fi

    # Get all chart-managed source names (both HTTP and OTLP variants for all signals).
    # This list is generated from values.yaml at helm render time via
    # chart-managed-sources.json, ensuring it stays in sync automatically.
    # Only sources whose names appear in this list are candidates for deletion.
    # Sources created manually (via UI or API) will never be touched.
    local KNOWN_CHART_SOURCES
    KNOWN_CHART_SOURCES=$(jq -r '.sources[]' /etc/terraform/chart-managed-sources.json 2>/dev/null)
    if [[ -z "${KNOWN_CHART_SOURCES}" ]]; then
        echo "WARNING: Could not read chart-managed-sources.json, skipping cleanup."
        return
    fi

    # Delete sources that are chart-managed but not in the current config
    while IFS=$'\t' read -r source_id source_name; do
        # Only consider sources that are known chart-managed sources
        if ! echo "${KNOWN_CHART_SOURCES}" | grep -qxF "${source_name}"; then
            continue
        fi
        # Delete if not in current expected config
        if ! echo "${EXPECTED_SOURCES}" | grep -qxF "${source_name}"; then
            echo "Deleting unused source: ${source_name} (id: ${source_id})"
            local DELETE_RESPONSE
            DELETE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -XDELETE \
                -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
                "${SUMOLOGIC_BASE_URL}v1/collectors/${COLLECTOR_ID}/sources/${source_id}")
            if [[ "${DELETE_RESPONSE}" == "200" ]]; then
                echo "  Successfully deleted source: ${source_name}"
            else
                echo "  WARNING: Failed to delete source ${source_name} (HTTP ${DELETE_RESPONSE})"
            fi
        fi
    done <<< "${EXISTING_SOURCES}"

    echo "Source cleanup complete."
}

# shellcheck disable=SC2154
if [[ "${CLEANUP_UNUSED_SOURCES}" == "true" ]]; then
    cleanup_unused_sources
else
    echo "Source cleanup skipped (cleanupUnusedSources is not enabled)."
fi

# Setup Sumo Logic monitors if enabled
if [[ "${SUMOLOGIC_MONITORS_ENABLED:?}" = "true" ]]; then
    bash /etc/terraform/monitors.sh
else
    echo "Installation of the Sumo Logic monitors is disabled."
    echo "You can install them manually later with:"
    echo "https://github.com/SumoLogic/terraform-sumologic-sumo-logic-monitor/tree/main/monitor_packages/kubernetes"
fi

# Setup Sumo Logic dashboards if enabled
if [[ "${SUMOLOGIC_DASHBOARDS_ENABLED:?}" = "true" ]]; then
    bash /etc/terraform/dashboards.sh
else
    echo "Installation of the Sumo Logic dashboards is disabled."
    echo "You can install them manually later with:"
    echo "https://www.sumologic.com/help/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app"
fi

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=

bash /etc/terraform/custom.sh
