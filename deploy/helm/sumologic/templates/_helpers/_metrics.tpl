{{/*
Check if any metrics provider is enabled
Example Usage:
{{- if eq (include "metrics.enabled" .) "true" }}

*/}}
{{- define "metrics.enabled" -}}
{{- $enabled := false -}}
{{- if eq (include "metrics.otelcol.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{ $enabled }}
{{- end -}}


{{/*
Check if otelcol metrics provider is enabled
Example Usage:
{{- if eq (include "metrics.otelcol.enabled" .) "true" }}

*/}}
{{- define "metrics.otelcol.enabled" -}}
{{- $enabled := false -}}
{{- if and (eq .Values.sumologic.metrics.enabled true) (eq .Values.metadata.metrics.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Generate list of remoteWrite endpoints for telegraf configuration

'{{ include "metric.endpoints" . }}'
*/}}
{{- define "metric.endpoints" -}}
{{- $endpoints := list -}}
{{- $kps := get .Values "kube-prometheus-stack" -}}
{{- range $remoteWrite := $kps.prometheus.prometheusSpec.remoteWrite }}
{{- $endpoints = append $endpoints ($remoteWrite.url | trimPrefix "http://$(METADATA_METRICS_SVC).$(NAMESPACE):9888" | quote) -}}
{{- end }}
{{- range $remoteWrite := $kps.prometheus.prometheusSpec.additionalRemoteWrite }}
{{- $endpoints = append $endpoints ($remoteWrite.url | trimPrefix "http://$(METADATA_METRICS_SVC).$(NAMESPACE):9888" | quote) -}}
{{- end -}}
{{- range $endpoint := .Values.metadata.metrics.config.additionalEndpoints }}
{{- $endpoints = append $endpoints ($endpoint | quote) -}}
{{- end -}}
{{- $endpoints := uniq $endpoints -}}
{{- $endpoints := sortAlpha $endpoints -}}
{{ $endpoints | join ",\n" }}
{{- end -}}

{{/*
Check if remote write proxy is enabled.
Example Usage:
{{- if eq (include "metrics.remoteWriteProxy.enabled" .) "true" }}

*/}}
{{- define "metrics.remoteWriteProxy.enabled" -}}
{{ and (eq (include "metrics.enabled" .) "true") (eq .Values.sumologic.metrics.remoteWriteProxy.enabled true) }}
{{- end -}}

{{- define "metrics.remoteWriteProxy.nodeSelector" -}}
{{- if .Values.sumologic.metrics.remoteWriteProxy.nodeSelector -}}
{{- toYaml .Values.sumologic.metrics.remoteWriteProxy.nodeSelector -}}
{{- else -}}
{{- template "kubernetes.defaultNodeSelector" . -}}
{{- end -}}
{{- end -}}

{{- define "metrics.remoteWriteProxy.tolerations" -}}
{{- if .Values.sumologic.metrics.remoteWriteProxy.tolerations -}}
{{- toYaml .Values.sumologic.metrics.remoteWriteProxy.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "metrics.remoteWriteProxy.affinity" -}}
{{- if .Values.sumologic.metrics.remoteWriteProxy.affinity -}}
{{- toYaml .Values.sumologic.metrics.remoteWriteProxy.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the otelcol metrics collector image
*/}}
{{- define "sumologic.metrics.collector.image" -}}
{{ template "utils.getOtelImage" (dict "overrideImage" .Values.sumologic.metrics.collector.otelcol.image "defaultImage" .Values.sumologic.otelcolImage) }}
{{- end -}}

{{- define "metrics.collector.otelcol.nodeSelector" -}}
{{- if .Values.sumologic.metrics.collector.otelcol.nodeSelector -}}
{{- toYaml .Values.sumologic.metrics.collector.otelcol.nodeSelector -}}
{{- else -}}
{{- template "kubernetes.defaultNodeSelector" . -}}
{{- end -}}
{{- end -}}

{{- define "metrics.collector.otelcol.tolerations" -}}
{{- if .Values.sumologic.metrics.collector.otelcol.tolerations -}}
{{- toYaml .Values.sumologic.metrics.collector.otelcol.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "metrics.collector.otelcol.affinity" -}}
{{- if .Values.sumologic.metrics.collector.otelcol.affinity -}}
{{- toYaml .Values.sumologic.metrics.collector.otelcol.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}

{{- define "metadata.metrics.statefulset.nodeSelector" -}}
{{- if .Values.metadata.metrics.statefulset.nodeSelector -}}
{{- toYaml .Values.metadata.metrics.statefulset.nodeSelector -}}
{{- else -}}
{{- template "kubernetes.defaultNodeSelector" . -}}
{{- end -}}
{{- end -}}

{{- define "metadata.metrics.statefulset.tolerations" -}}
{{- if .Values.metadata.metrics.statefulset.tolerations -}}
{{- toYaml .Values.metadata.metrics.statefulset.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "metadata.metrics.statefulset.affinity" -}}
{{- if .Values.metadata.metrics.statefulset.affinity -}}
{{- toYaml .Values.metadata.metrics.statefulset.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}

{{- define "sumologic.labels.app.metrics" -}}
{{ template "sumologic.labels.app.otelcol" . }}-metrics
{{- end -}}

{{- define "sumologic.labels.app.metrics.pod" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.service" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.service-headless" -}}
{{- template "sumologic.labels.app.metrics.service" . }}-headless
{{- end -}}

{{- define "sumologic.labels.app.metrics.configmap" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.statefulset" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.hpa" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy" -}}
{{- template "sumologic.fullname" . }}-remote-write-proxy
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.configmap" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.deployment" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.pod" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.service" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics" -}}
{{ template "sumologic.metadata.name.otelcol" . }}-metrics
{{- end -}}

{{- define "sumologic.metrics.metadata.endpoint" -}}
{{- if .Values.sumologic.metrics.remoteWriteProxy.enabled -}}
{{ template "sumologic.metadata.name.remoteWriteProxy.service" . }}
{{- else -}}
{{ template "sumologic.metadata.name.metrics.service" . }}
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.service" -}}
{{ template "sumologic.fullname" . }}-metadata-metrics
{{- end -}}

{{- define "sumologic.metadata.name.metrics.service-headless" -}}
{{ template "sumologic.metadata.name.metrics" . }}-headless
{{- end -}}

{{- define "sumologic.metadata.name.metrics.configmap" -}}
{{ template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.statefulset" -}}
{{ template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.pdb" -}}
{{ template "sumologic.metadata.name.metrics.statefulset" . }}-pdb
{{- end -}}

{{- define "sumologic.metadata.name.metrics.hpa" -}}
{{- template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy" -}}
{{ template "sumologic.fullname" . }}-remote-write-proxy
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy.configmap" -}}
{{ template "sumologic.metadata.name.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy.deployment" -}}
{{ template "sumologic.metadata.name.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy.service" -}}
{{ template "sumologic.metadata.name.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.metrics" -}}
sumologic.com/app: otelcol-metrics
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.labels.metrics.remoteWriteProxy" -}}
sumologic.com/app: metrics-remote-write-proxy
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.label.scrape" -}}
sumologic.com/scrape: "true"
{{- end -}}

{{- define "sumologic.labels.scrape.metrics" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.metrics" -}}
{{- template "sumologic.metadata.name.pvcCleaner" . }}-metrics
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.metrics" -}}
{{- template "sumologic.labels.app.pvcCleaner" . }}-metrics
{{- end -}}

{{/*
Definitions for metrics collector
*/}}

{{- define "sumologic.labels.component.metrics" -}}
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.labels.app.metrics.collector" -}}
sumologic.com/app: otelcol
{{- end -}}

{{- define "sumologic.labels.app.metrics.collector.pod" -}}
{{ template "sumologic.labels.app.metrics.collector" . }}
{{ template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.clusterrole" -}}
{{- template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.clusterrolebinding" -}}
{{- template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.serviceaccount" -}}
{{- template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.opentelemetrycollector" -}}
{{ template "sumologic.labels.app.metrics.collector" . }}
{{ template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector" -}}
{{- template "sumologic.fullname" . }}-metrics
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.opentelemetrycollector" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.serviceaccount" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.clusterrole" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.clusterrolebinding.prometheus" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}-prometheus
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.clusterrolebinding.metadata" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}-metadata
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.name" -}}
{{ template "sumologic.metadata.name.metrics.collector.opentelemetrycollector" . }}-targetallocator
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.serviceaccount" -}}
{{ template "sumologic.metadata.name.metrics.targetallocator.name" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.clusterrole" -}}
{{ template "sumologic.metadata.name.metrics.targetallocator.name" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.clusterrolebinding" -}}
{{ template "sumologic.metadata.name.metrics.targetallocator.name" . }}
{{- end -}}

{{/*
Return the metrics format for the default Sumologic exporter for metrics.
'{{ include "metrics.otelcol.exporter.format" . }}'
*/}}
{{- define "metrics.otelcol.exporter.format" -}}
{{- if eq .Values.sumologic.metrics.sourceType "http" -}}
{{- "prometheus" -}}
{{- else if eq .Values.sumologic.metrics.sourceType "otlp" -}}
{{- "otlp" -}}
{{- else -}}
{{- fail "`sumologic.metrics.sourceType` can only be `http` or `otlp`" -}}
{{- end -}}
{{- end -}}

{{/*
Return the endpoint for the default Sumologic exporter for metrics.
'{{ include "metrics.otelcol.exporter.endpoint" . }}'
*/}}
{{- define "metrics.otelcol.exporter.endpoint" -}}
{{- if eq .Values.sumologic.metrics.sourceType "http" -}}
{{- "${SUMO_ENDPOINT_DEFAULT_METRICS_SOURCE}" -}}
{{- else if eq .Values.sumologic.metrics.sourceType "otlp" -}}
{{- "${SUMO_ENDPOINT_DEFAULT_OTLP_METRICS_SOURCE}" -}}
{{- else -}}
{{- fail "`sumologic.metrics.sourceType` can only be `http` or `otlp`" -}}
{{- end -}}
{{- end -}}

{{/*
Check if autoscaling for metadata metrics is enabled.

Example Usage:
{{- if eq (include "metadata.metrics.autoscaling.enabled" .) "true" }}

*/}}
{{- define "metadata.metrics.autoscaling.enabled" -}}
{{- template "is.autoscaling.enabled" (dict "autoscalingEnabled" .Values.metadata.metrics.autoscaling.enabled "Values" .Values) -}}
{{- end -}}

{{/*
Check if autoscaling for metrics collector is enabled.

Example Usage:
{{- if eq (include "metrics.collector.autoscaling.enabled" .) "true" }}

*/}}
{{- define "metrics.collector.autoscaling.enabled" -}}
{{- template "is.autoscaling.enabled" (dict "autoscalingEnabled" .Values.sumologic.metrics.collector.otelcol.autoscaling.enabled "Values" .Values) -}}
{{- end -}}

{{/*
Returns list of namespaces to exclude

Example:

{{ include "metrics.excludeNamespaces" . }}
*/}}
{{- define "metrics.excludeNamespaces" -}}
{{- $excludeNamespaceRegex := .Values.sumologic.metrics.excludeNamespaceRegex | quote -}}
{{- if eq .Values.sumologic.collectionMonitoring false -}}
  {{- if .Values.sumologic.metrics.excludeNamespaceRegex -}}
  {{- $excludeNamespaceRegex = printf "%s|%s" ( include "sumologic.namespace" .  ) .Values.sumologic.metrics.excludeNamespaceRegex | quote -}}
  {{- else -}}
  {{- $excludeNamespaceRegex = printf "%s" ( include "sumologic.namespace" .  ) | quote -}}
  {{- end -}}
{{- end -}}
{{ print $excludeNamespaceRegex }}
{{- end -}}
