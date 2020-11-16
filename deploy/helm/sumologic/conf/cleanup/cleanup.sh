#!/bin/sh

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL%v1*}
# Support proxy for terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

cd /cleanup/ || exit 1

readonly COLLECTOR_NAME="{{- if .Values.sumologic.collectorName }}{{ .Values.sumologic.collectorName }}{{- else}}{{ .Values.sumologic.clusterName }}{{- end}}"

terraform init

terraform import sumologic_collector.collector "${COLLECTOR_NAME}"
terraform import kubernetes_secret.sumologic_collection_secret {{ .Release.Namespace }}/sumologic

terraform destroy -auto-approve .

# Cleanup env variables
export SUMOLOGIC_BASE_URL=
export SUMOLOGIC_ACCESSKEY=
export SUMOLOGIC_ACCESSID=
