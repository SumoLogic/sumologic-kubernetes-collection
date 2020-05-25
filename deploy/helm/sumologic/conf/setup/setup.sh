#!/bin/sh
cp /etc/terraform/sumo-k8s.tf /terraform
cd /terraform

# Fix URL to remove "v1" or "v1/"
export SUMOLOGIC_BASE_URL=${SUMOLOGIC_BASE_URL%v1*}

# Support proxy for terraform
export HTTP_PROXY=${HTTP_PROXY:=""}
export HTTPS_PROXY=${HTTPS_PROXY:=""}

COLLECTOR_NAME={{- if .Values.sumologic.collectorName }}{{ .Values.sumologic.collectorName }}{{- else}}{{ .Values.sumologic.clusterName }}{{- end}}

terraform init

# Sumo Collector and HTTP sources
terraform import sumologic_collector.collector "$COLLECTOR_NAME"
{{ range $source := .Values.sumologic.sources }}
terraform import sumologic_http_source.{{ template "sources.terraform_name" $source }} "$COLLECTOR_NAME/{{ $source.value }}"
{{- end }}

# Kubernetes Namespace and Secret
terraform import kubernetes_namespace.sumologic_collection_namespace {{ .Release.Namespace }}
terraform import kubernetes_secret.sumologic_collection_secret {{ .Release.Namespace }}/sumologic

terraform apply -auto-approve