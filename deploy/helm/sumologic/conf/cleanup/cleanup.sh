#!/bin/bash

set -euo pipefail

# Support proxy for Terraform
export HTTP_PROXY="${HTTP_PROXY:=""}"
export HTTPS_PROXY="${HTTPS_PROXY:=""}"
export NO_PROXY="${NO_PROXY:=""}"

readonly SUMOLOGIC_COLLECTOR_NAME="${SUMOLOGIC_COLLECTOR_NAME:?}"
readonly SUMOLOGIC_SECRET_NAME="${SUMOLOGIC_SECRET_NAME:?}"
readonly NAMESPACE="${NAMESPACE:?}"

# Set variables for terraform
export TF_VAR_collector_name="${SUMOLOGIC_COLLECTOR_NAME}"
export TF_VAR_secret_name="${SUMOLOGIC_SECRET_NAME}"
export TF_VAR_chart_version="${CHART_VERSION:?}"
export TF_VAR_namespace_name="${NAMESPACE:?}"
export TF_VAR_use_extension="${SUMOLOGIC_USE_EXTENSION:-false}"
export TF_VAR_extension_secret_name="${SUMOLOGIC_EXTENSION_SECRET_NAME:-sumologic-extension}"
export TF_VAR_provided_installation_token="${SUMOLOGIC_INSTALLATION_TOKEN:-}"

cp /etc/terraform/* /terraform/
cd /terraform || exit 1

# Normalize base URL: strip trailing "v1..." so API calls can safely prepend "v1/".
# The endpoint value from Helm may already contain a trailing "v1/" path component.
SUMOLOGIC_BASE_URL="${SUMOLOGIC_BASE_URL%v1*}"
export SUMOLOGIC_BASE_URL

# Fall back to init -upgrade to prevent:
# Error: Inconsistent dependency lock file
terraform init -input=false -get=false || terraform init -input=false -upgrade

if [[ "${SUMOLOGIC_USE_EXTENSION:-false}" != "true" ]]; then
    # Non-extension mode: import hosted collector and sumologic secret.
    terraform import 'sumologic_collector.collector[0]' "${SUMOLOGIC_COLLECTOR_NAME}" || true
    terraform import 'kubernetes_secret.sumologic_collection_secret[0]' "${NAMESPACE}/${SUMOLOGIC_SECRET_NAME}" || true
else
    # Extension mode: import token and extension secret only when Terraform owns them
    # (i.e. installationToken was NOT provided via values — empty provided_installation_token).
    if [[ -z "${SUMOLOGIC_INSTALLATION_TOKEN:-}" ]]; then
        TOKEN_RESPONSE="$(curl -s -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
            "${SUMOLOGIC_BASE_URL}v1/tokens?limit=1000")"
        if ! jq -e '.data' <<< "${TOKEN_RESPONSE}" > /dev/null 2>&1; then
            echo "WARNING: Token API response does not contain .data — skipping token import. Response: ${TOKEN_RESPONSE}"
        fi
        JQ_OUTPUT=$(jq -r ".data[]? | select(.name == \"kubernetes-collection-${SUMOLOGIC_COLLECTOR_NAME}\") | .id" <<< "${TOKEN_RESPONSE}")
        TOKEN_ID=$(head -1 <<< "${JQ_OUTPUT}")
        if [[ -n "${TOKEN_ID}" ]]; then
            terraform import 'sumologic_token.collection_token[0]' "${TOKEN_ID}" || { echo "WARNING: failed to import sumologic_token.collection_token[0] (${TOKEN_ID})"; sleep 60; }
        fi
        terraform import 'kubernetes_secret.extension_secret[0]' \
            "${NAMESPACE}/${TF_VAR_extension_secret_name}" || { echo "WARNING: failed to import kubernetes_secret.extension_secret[0] (${NAMESPACE}/${TF_VAR_extension_secret_name})"; sleep 60; }
    fi
fi

terraform destroy -auto-approve

# Terraform only deletes the extension secret if it was successfully imported into state.
# Delete it directly as a fallback to guarantee cleanup even when the import was skipped.
if [[ "${SUMOLOGIC_USE_EXTENSION:-false}" == "true" && -z "${SUMOLOGIC_INSTALLATION_TOKEN:-}" ]]; then
    kubectl delete secret "${TF_VAR_extension_secret_name}" \
        --namespace "${NAMESPACE}" --ignore-not-found
fi

# Cleanup env variables
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=
