#!/bin/sh
cp /etc/terraform/*.tf /terraform
cd /terraform

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL%v1*}

# Support proxy for terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}
export NO_PROXY=${NO_PROXY:=""}

COLLECTOR_NAME="{{- if .Values.sumologic.collectorName }}{{ .Values.sumologic.collectorName }}{{- else}}{{ .Values.sumologic.clusterName }}{{- end}}"

terraform init

# Sumo Collector and HTTP sources
terraform import sumologic_collector.collector "$COLLECTOR_NAME"
{{- $ctx := .Values -}}
{{- range $type, $sources := .Values.sumologic.sources }}
{{- range $key, $source := $sources }}
{{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
terraform import sumologic_http_source.{{ template "terraform.sources.name" (dict "Name" $key "Type" $type) }} "$COLLECTOR_NAME/{{ $source.name }}"
{{- end }}
{{- end }}
{{- end }}


# Kubernetes Secret
terraform import kubernetes_secret.sumologic_collection_secret {{ .Release.Namespace }}/sumologic

terraform apply -auto-approve