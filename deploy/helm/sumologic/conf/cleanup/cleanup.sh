#!/bin/bash

set -euo pipefail

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL="${SUMOLOGIC_BASE_URL%v1*}"
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

cp /etc/terraform/* /terraform/
cd /terraform || exit 1

# Fall back to init -upgrade to prevent:
# Error: Inconsistent dependency lock file
terraform init -input=false -get=false || terraform init -input=false -upgrade

# shellcheck disable=SC1083
terraform import sumologic_collector.collector "${SUMOLOGIC_COLLECTOR_NAME}"
# shellcheck disable=SC1083
terraform import kubernetes_secret.sumologic_collection_secret "${NAMESPACE}/${SUMOLOGIC_SECRET_NAME}"

terraform destroy -auto-approve

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=
