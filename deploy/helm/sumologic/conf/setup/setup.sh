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
terraform import sumologic_http_source.default_metrics_source "$COLLECTOR_NAME/(default-metrics)"
terraform import sumologic_http_source.apiserver_metrics_source "$COLLECTOR_NAME/apiserver-metrics"
terraform import sumologic_http_source.events_source "$COLLECTOR_NAME/events"
terraform import sumologic_http_source.kube_controller_manager_metrics_source "$COLLECTOR_NAME/kube-controller-manager-metrics"
terraform import sumologic_http_source.kube_scheduler_metrics_source "$COLLECTOR_NAME/kube-scheduler-metrics"
terraform import sumologic_http_source.kube_state_metrics_source "$COLLECTOR_NAME/kube-state-metrics"
terraform import sumologic_http_source.kubelet_metrics_source "$COLLECTOR_NAME/kubelet-metrics"
terraform import sumologic_http_source.logs_source "$COLLECTOR_NAME/logs"
terraform import sumologic_http_source.node_exporter_metrics_source "$COLLECTOR_NAME/node-exporter-metrics"

# Kubernetes Namespace and Secret
terraform import kubernetes_namespace.sumologic_collection_namespace {{ .Release.Namespace }}
terraform import kubernetes_secret.sumologic_collection_secret {{ .Release.Namespace }}/sumologic

terraform apply -auto-approve