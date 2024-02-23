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
{{ $enabled }}
{{- end -}}


{{/*
Check if otelcol logs metadata provider is enabled

Example Usage:
{{- if eq (include "logs.otelcol.enabled" .) "true" }}

*/}}
{{- define "logs.otelcol.enabled" -}}
{{- $enabled := false -}}
{{- if and (eq .Values.sumologic.logs.enabled true) (eq .Values.metadata.logs.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Check if otelcol logs collector is enabled.
It's enabled if both logs in general and the collector specifically are enabled.

Example Usage:
{{- if eq (include "logs.collector.otelcol.enabled" .) "true" }}

*/}}
{{- define "logs.collector.otelcol.enabled" -}}
{{- $enabled := and (eq (include "logs.enabled" .) "true") (eq .Values.sumologic.logs.collector.otelcol.enabled true) -}}
{{ $enabled }}
{{- end -}}

{{- define "logs.collector.otelcloudwatch.enabled" -}}
{{- $enabled := and (eq (include "logs.enabled" .) "true") (eq .Values.sumologic.logs.collector.otelcloudwatch.enabled true) -}}
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

{{/*
Return the exporters for container log pipeline.

'{{ include "logs.otelcol.container.exporters" . }}'
*/}}
{{- define "logs.otelcol.container.exporters" -}}
{{- if eq .Values.sumologic.logs.sourceType "http" -}}
- sumologic/containers
{{- if eq (include "sumologic-mock.forward-logs-metadata" .) "true" }}
- sumologic/sumologic-mock-containers
{{- end }}
{{- else if eq .Values.sumologic.logs.sourceType "otlp" }}
- sumologic
{{- if eq (include "sumologic-mock.forward-logs-metadata" .) "true" }}
- sumologic/sumologic-mock
{{- end }}
{{- else -}}
{{- fail "`sumologic.logs.sourceType` can only be `http` or `otlp`" -}}
{{- end -}}
{{- if eq .Values.debug.logs.metadata.print true }}
- debug
{{- end }}
{{- end -}}

{{/*
Return the exporters for systemd log pipeline.

'{{ include "logs.otelcol.systemd.exporters" . }}'
*/}}
{{- define "logs.otelcol.systemd.exporters" -}}
{{- if eq .Values.sumologic.logs.sourceType "http" -}}
- sumologic/systemd
{{- if eq (include "sumologic-mock.forward-logs-metadata" .) "true" }}
- sumologic/sumologic-mock-systemd
{{- end }}
{{- else if eq .Values.sumologic.logs.sourceType "otlp" }}
- sumologic
{{- if eq (include "sumologic-mock.forward-logs-metadata" .) "true" }}
- sumologic/sumologic-mock
{{- end }}
{{- else -}}
{{- fail "`sumologic.logs.sourceType` can only be `http` or `otlp`" -}}
{{- end -}}
{{- if eq .Values.debug.logs.metadata.print true }}
- debug
{{- end }}
{{- end -}}

{{/*
Return the exporters for kubelet log pipeline.

'{{ include "logs.otelcol.kubelet.exporters" . }}'
*/}}
{{- define "logs.otelcol.kubelet.exporters" -}}
{{- if eq .Values.sumologic.logs.sourceType "http" }}
- sumologic/systemd
{{- if eq (include "sumologic-mock.forward-logs-metadata" .) "true" }}
- sumologic/sumologic-mock-systemd
{{- end }}
{{- else if eq .Values.sumologic.logs.sourceType "otlp" }}
- sumologic
{{- if eq (include "sumologic-mock.forward-logs-metadata" .) "true" }}
- sumologic/sumologic-mock
{{- end }}
{{- else }}
{{- fail "`sumologic.logs.sourceType` can only be `http` or `otlp`" -}}
{{- end -}}
{{- if eq .Values.debug.logs.metadata.print true }}
- debug
{{- end }}
{{- end -}}

{{- define "sumologic.labels.app.logs" -}}
{{ template "sumologic.labels.app.otelcol" . }}-logs
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.configmap" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.serviceaccount" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.cloudwatch.serviceaccount" -}}
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

{{- define "sumologic.labels.app.logs.cloudwatch.pvc" -}}
{{- printf "file-storage-%s-sumologic-otelcol-logs-0" .Release.Name -}}
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
{{ template "sumologic.metadata.name.otelcol" . }}-logs
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
sumologic.com/app: otelcol-logs
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
  {{- $excludeNamespaceRegex = printf "%s|%s" ( include "sumologic.namespace" .  ) .Values.sumologic.logs.container.excludeNamespaceRegex | quote -}}
  {{- else -}}
  {{- $excludeNamespaceRegex = printf "%s" ( include "sumologic.namespace" .  ) | quote -}}
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

{{- define "sumologic.logs.collector.tolerations" -}}
{{- if .Values.otellogs.daemonset.tolerations  -}}
{{- toYaml .Values.otellogs.daemonset.tolerations  -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{/*
Check if autoscaling for metadata logs is enabled.

Example Usage:
{{- if eq (include "metadata.logs.autoscaling.enabled" .) "true" }}

*/}}
{{- define "metadata.logs.autoscaling.enabled" -}}
{{- template "is.autoscaling.enabled" (dict "autoscalingEnabled" .Values.metadata.logs.autoscaling.enabled "Values" .Values) }}
{{- end -}}

{{- define "metadata.logs.statefulset.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.metadata.logs.statefulset.nodeSelector)}}
{{- end -}}

{{- define "metadata.logs.statefulset.tolerations" -}}
{{- if .Values.metadata.logs.statefulset.tolerations -}}
{{- toYaml .Values.metadata.logs.statefulset.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "metadata.logs.statefulset.affinity" -}}
{{- if .Values.metadata.logs.statefulset.affinity -}}
{{- toYaml .Values.metadata.logs.statefulset.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}

{{- define "logs.collector.files.list" }}
{{- if eq (include "logs.collector.otelcol.enabled" .) "true" }}
{{- $ctx := . }}
{{- $instance := "" -}}
{{- $daemonsets := dict "" $.Values.otellogs.daemonset  -}}
{{- $daemonsets = deepCopy $daemonsets | merge $.Values.otellogs.additionalDaemonSets -}}
{{- range $name, $value := $daemonsets }}
{{- if not (eq $name "") }}
{{- $instance = (printf "-%s" $name ) }}
{{- end }}
- /var/log/pods/{{ template "sumologic.namespace"  $ctx }}_{{ printf "%s%s" (include "sumologic.metadata.name.logs.collector.daemonset" $ctx) $instance | trunc 63 | trimSuffix "-" }}*/*/*.log
{{- end }}
{{- end }}
{{- end }}

{{- define "logs.metadata.files.list" -}}
- /var/log/pods/{{ template "sumologic.namespace" . }}_{{ template "sumologic.metadata.name.logs.statefulset" . }}*/*/*.log
{{- end -}}
