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
export TF_VAR_provided_installation_token="${SUMOLOGIC_INSTALLATION_TOKEN_PROVIDED:-false}"

cp /etc/terraform/* /terraform/
cd /terraform || exit 1

# Resolve the correct regional base URL, following any HTTP redirects.
# Mirrors fix_sumo_base_url() in setup.sh to handle tenants on non-US deployments.
function fix_sumo_base_url() {
  local BASE_URL="${SUMOLOGIC_BASE_URL}"
  if [[ "${BASE_URL}" =~ ^\s*$ ]]; then
    BASE_URL="https://api.sumologic.com/api/"
  fi
  # shellcheck disable=SC2312
  local OPTIONAL_REDIRECTION
  OPTIONAL_REDIRECTION="$(curl -XGET -s -o /dev/null -D - \
      -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
      "${BASE_URL}v1/collectors" \
      | grep -Fi location)"
  if [[ ! "${OPTIONAL_REDIRECTION}" =~ ^\s*$ ]]; then
    BASE_URL=$(echo "${OPTIONAL_REDIRECTION}" | sed -E 's/.*: (https:\/\/.*(au|ca|de|eu|fed|in|jp|kr|ch|esc|us2)?\.sumologic\.com\/api\/).*/\1/')
  fi
  BASE_URL="${BASE_URL%v1*}"
  echo "${BASE_URL}"
}

SUMOLOGIC_BASE_URL="$(fix_sumo_base_url)"
export SUMOLOGIC_BASE_URL

# Fall back to init -upgrade to prevent:
# Error: Inconsistent dependency lock file
terraform init -input=false -get=false || terraform init -input=false -upgrade

if [[ "${SUMOLOGIC_USE_EXTENSION:-false}" != "true" ]]; then
    # Non-extension mode: import hosted collector and sumologic secret.
    terraform import 'sumologic_collector.collector[0]' "${SUMOLOGIC_COLLECTOR_NAME}" || true
    terraform import 'kubernetes_secret.sumologic_collection_secret[0]' "${NAMESPACE}/${SUMOLOGIC_SECRET_NAME}" || true
else
    # Extension mode: import token and extension secret only when Terraform owns them (i.e., not provided by user via helm values).
    if [[ "${TF_VAR_provided_installation_token}" != "true" ]]; then
        TOKEN_RESPONSE="$(curl -s -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
            "${SUMOLOGIC_BASE_URL}v1/tokens?limit=1000" || echo "{}")"
        JQ_OUTPUT=$(jq -r ".data[]? | select(.name == \"kubernetes-collection-${SUMOLOGIC_COLLECTOR_NAME}\") | .id" <<< "${TOKEN_RESPONSE}")
        TOKEN_ID=$(head -1 <<< "${JQ_OUTPUT}")
        if [[ -n "${TOKEN_ID}" ]]; then
            terraform import 'sumologic_token.collection_token[0]' "${TOKEN_ID}" || true
        fi
        terraform import 'kubernetes_secret.extension_secret[0]' \
            "${NAMESPACE}/${TF_VAR_extension_secret_name}" || true
    fi
fi

terraform destroy -auto-approve

# Cleanup env variables
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=
