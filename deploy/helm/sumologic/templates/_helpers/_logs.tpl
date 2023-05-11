{{/*
Check if any logs metadata provider is enabled

Example Usage:
{{- if eq (include "logs.enabled" .) "true" }}

*/}}
{{- define "logs.enabled" -}}
{{- $enabled := false -}}
{{- if eq (include "logs.otelcol.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{- if eq (include "logs.fluentd.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{ $enabled }}
{{- end -}}


{{/*
Check if otelcol logs metadata provider is enabled

Example Usage:
{{- if eq (include "logs.otelcol.enabled" .) "true" }}

*/}}
{{- define "logs.otelcol.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.logs.enabled true -}}
{{- if and (eq .Values.sumologic.logs.metadata.provider "otelcol") (eq .Values.metadata.logs.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Check if fluentd logs metadata provider is enabled

Example Usage:
{{- if eq (include "logs.fluentd.enabled" .) "true" }}

*/}}
{{- define "logs.fluentd.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.logs.enabled true -}}
{{- if and (eq .Values.sumologic.logs.metadata.provider "fluentd") (eq .Values.fluentd.logs.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Check if otelcol logs collector is enabled.
It's enabled if both logs in general and the collector specifically are enabled.
If both the collector and Fluent-Bit are enabled, we error.

Example Usage:
{{- if eq (include "logs.collector.otelcol.enabled" .) "true" }}

*/}}
{{- define "logs.collector.otelcol.enabled" -}}
{{- $enabled := and (eq (include "logs.enabled" .) "true") (eq .Values.sumologic.logs.collector.otelcol.enabled true) -}}
{{- $fluentBitEnabled := index .Values "fluent-bit" "enabled" -}}
{{- if kindIs "invalid" $fluentBitEnabled -}}
{{- $fluentBitEnabled = true -}}
{{- end -}}
{{- $sideBySideAllowed := .Values.sumologic.logs.collector.allowSideBySide -}}
{{- if and $enabled $fluentBitEnabled (not $sideBySideAllowed) -}}
{{- fail "Fluent-Bit and Otel log collector can't be enabled at the same time. Set either `fluent-bit.enabled` or `sumologic.logs.collector.otelcol.enabled` to false" -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{- define "logs.collector.otelcloudwatch.enabled" -}}
{{- $enabled := and (eq (include "logs.enabled" .) "true") (eq .Values.sumologic.logs.collector.otelcloudwatch.enabled true) -}}
{{- end -}}

{{/*
Check if Fluent-Bit logs collector is enabled.
It's enabled if logs in general are enabled and fluent-bit.enabled is set to true.

Example Usage:
{{- if eq (include "logs.collector.fluentbit.enabled" .) "true" }}

*/}}
{{- define "logs.collector.fluentbit.enabled" -}}
{{- $fluentBitEnabled := index .Values "fluent-bit" "enabled" -}}
{{- if kindIs "invalid" $fluentBitEnabled -}}
{{- $fluentBitEnabled = true -}}
{{- end -}}
{{- $enabled := and (eq (include "logs.enabled" .) "true") $fluentBitEnabled -}}
{{- $otelLogCollectorEnabled := .Values.sumologic.logs.collector.otelcol.enabled -}}
{{- $sideBySideAllowed := .Values.sumologic.logs.collector.allowSideBySide -}}
{{- if and $enabled $otelLogCollectorEnabled (not $sideBySideAllowed) -}}
{{- fail "Fluent-Bit and Otel log collector can't be enabled at the same time. Set either `fluent-bit.enabled` or `sumologic.logs.collector.otelcol.enabled` to false" -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Return the log format for the Sumologic exporter for container logs.

'{{ include "logs.otelcol.container.exporter.format" . }}'
*/}}
{{- define "logs.otelcol.container.exporter.format" -}}
{{- $jsonFormats := list "json" "fields" "json_merge" -}}
{{- if has .Values.sumologic.logs.container.format $jsonFormats -}}
{{- "json" -}}
{{- else if eq .Values.sumologic.logs.container.format "text" -}}
{{- "text" -}}
{{- else -}}
{{- fail "`sumologic.logs.container.format` can only be `json`, `text`, `json_merge` or `fields`" -}}
{{- end -}}
{{- end -}}

{{- define "sumologic.labels.app.logs" -}}
{{- if eq .Values.sumologic.logs.metadata.provider "fluentd" -}}
{{ template "sumologic.labels.app.fluentd" . }}-logs
{{- else if eq .Values.sumologic.logs.metadata.provider "otelcol" -}}
{{ template "sumologic.labels.app.otelcol" . }}-logs
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.configmap" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.serviceaccount" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.daemonset" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.statefulset" -}}
{{- template "sumologic.metadata.name.logs.collector.cloudwatch" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.service" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector" -}}
{{- template "sumologic.fullname" . }}-otelcol-logs-collector
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.configmap" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.serviceaccount" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.daemonset" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.pod" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.service" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.cloudwatch.configmap" -}}
{{- template "sumologic.fullname" . }}-otelcloudwatch-logs-collector
{{- end -}}

{{- define "sumologic.labels.app.logs.cloudwatch.service" -}}
{{- template "sumologic.metadata.name.logs.collector.cloudwatch" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.cloudwatch.service-headless" -}}
{{- template "sumologic.labels.app.logs.cloudwatch.service" . }}-headless
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.statefulset" -}}
{{- template "sumologic.fullname" . }}-otelcloudwatch-logs-collector
{{- end -}}

{{- define "sumologic.labels.app.logs.pod" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.service" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.service-headless" -}}
{{- template "sumologic.labels.app.logs.service" . }}-headless
{{- end -}}

{{- define "sumologic.labels.app.logs.configmap" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.statefulset" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.hpa" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs" -}}
{{- if eq .Values.sumologic.logs.metadata.provider "fluentd" -}}
{{ template "sumologic.metadata.name.fluentd" . }}-logs
{{- else if eq .Values.sumologic.logs.metadata.provider "otelcol" -}}
{{ template "sumologic.metadata.name.otelcol" . }}-logs
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.logs.service" -}}
{{ template "sumologic.fullname" . }}-metadata-logs
{{- end -}}

{{- define "sumologic.metadata.name.logs.service-headless" -}}
{{ template "sumologic.metadata.name.logs" . }}-headless
{{- end -}}

{{- define "sumologic.metadata.name.logs.configmap" -}}
{{ template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.statefulset" -}}
{{ template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.pdb" -}}
{{ template "sumologic.metadata.name.logs.statefulset" . }}-pdb
{{- end -}}

{{- define "sumologic.metadata.name.logs.hpa" -}}
{{- template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector" -}}
{{- template "sumologic.fullname" . }}-otelcol-logs-collector
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.cloudwatch" -}}
{{- template "sumologic.fullname" . }}-otelcol-cloudwatch-collector
{{- end -}}

{{- define "sumologic.labels.logs" -}}
sumologic.com/app: fluentd-logs
sumologic.com/component: logs
{{- end -}}

{{- define "sumologic.labels.logs.collector" -}}
sumologic.com/app: otelcol-logs-collector
sumologic.com/component: logs
{{- end -}}

{{- define "sumologic.labels.scrape.logs" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.logs" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.logs.collector" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.logs" -}}
{{- template "sumologic.metadata.name.pvcCleaner" . }}-logs
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.logs" -}}
{{- template "sumologic.labels.app.pvcCleaner" . }}-logs
{{- end -}}

{{/*
Returns list of namespaces to exclude

Example:

{{ include "logs.excludeNamespaces" . }}
*/}}
{{- define "logs.excludeNamespaces" -}}
{{- $excludeNamespaceRegex := .Values.sumologic.logs.container.excludeNamespaceRegex | quote -}}
{{- if eq .Values.sumologic.collectionMonitoring false -}}
  {{- if .Values.sumologic.logs.container.excludeNamespaceRegex -}}
  {{- $excludeNamespaceRegex = printf "%s|%s" .Release.Namespace .Values.sumologic.logs.container.excludeNamespaceRegex | quote -}}
  {{- else -}}
  {{- $excludeNamespaceRegex = printf "%s" .Release.Namespace | quote -}}
  {{- end -}}
{{- end -}}
{{ print $excludeNamespaceRegex }}
{{- end -}}

{{/*
Return the otelcol log collector image
*/}}
{{- define "sumologic.logs.collector.image" -}}
{{ template "utils.getOtelImage" (dict "overrideImage" .Values.otellogs.image "defaultImage" .Values.sumologic.otelcolImage) }}
{{- end -}}
