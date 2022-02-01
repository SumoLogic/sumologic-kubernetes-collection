#!/bin/sh

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL%v1*}
# Support proxy for Terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

cp /etc/terraform/*.tf /terraform/
cd /terraform || exit 1

# Fall back to init -upgrade to prevent:
# Error: Inconsistent dependency lock file
terraform init -input=false -get=false || terraform init -input=false -upgrade

# shellcheck disable=SC1083
terraform import sumologic_collector.collector {{ template "terraform.collector.name" . }}
# shellcheck disable=SC1083
terraform import kubernetes_secret.sumologic_collection_secret {{ template "terraform.secret.fullname" . }}

terraform destroy -auto-approve .

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=
