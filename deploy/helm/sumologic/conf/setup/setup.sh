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
    BASE_URL=$( echo "${OPTIONAL_REDIRECTION}" | sed -E 's/.*: (https:\/\/.*(au|ca|de|eu|fed|in|jp|kr|us2)?\.sumologic\.com\/api\/).*/\1/' )
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
    echo "Please refer to https://help.sumologic.com/docs/manage/fields/ to manually create the fields after you have removed unused fields to free up capacity."
fi

# Sumo Logic Collector and HTTP sources
# Only import sources when collector exists.
if terraform import sumologic_collector.collector "${SUMOLOGIC_COLLECTOR_NAME}"; then
    jq -r '.resource[] | to_entries[] | "\(.key) \(.value.name)"' sources.tf.json | while read -r resource_name source_name; do
        terraform import "sumologic_http_source.${resource_name}" "${SUMOLOGIC_COLLECTOR_NAME}/${source_name}"
    done || true
fi

# Kubernetes Secret
terraform import kubernetes_secret.sumologic_collection_secret "${NAMESPACE}/${SUMOLOGIC_SECRET_NAME}"

# Apply planned changes
TF_LOG_PROVIDER=DEBUG terraform apply \
    -auto-approve \
    -var="create_fields=${CREATE_FIELDS}" \
    || { echo "Error during applying Terraform changes"; exit 1; }

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
    echo "https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app"
fi

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=

bash /etc/terraform/custom.sh
