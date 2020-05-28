{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "sumologic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sumologic.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Create default fully qualified labels.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sumologic.labels.app" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs" -}}
{{- template "sumologic.fullname" . }}-fluentd-logs
{{- end -}}

{{- define "sumologic.labels.app.logs.headless" -}}
{{- template "sumologic.fullname" . }}-fluentd-logs-headless
{{- end -}}

{{- define "sumologic.labels.app.logs.configmap" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.statefulset" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics" -}}
{{- template "sumologic.fullname" . }}-fluentd-metrics
{{- end -}}

{{- define "sumologic.labels.app.metrics.headless" -}}
{{- template "sumologic.fullname" . }}-fluentd-metrics-headless
{{- end -}}

{{- define "sumologic.labels.app.metrics.configmap" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.statefulset" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.events" -}}
{{- template "sumologic.fullname" . }}-fluentd-events
{{- end -}}

{{- define "sumologic.labels.app.events.headless" -}}
{{- template "sumologic.fullname" . }}-fluentd-events-headless
{{- end -}}

{{- define "sumologic.labels.app.events.configmap" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.events.statefulset" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcol" -}}
{{- template "sumologic.fullname" . }}-otelcol
{{- end -}}

{{- define "sumologic.labels.app.otelcol.configmap" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcol.deployment" -}}
{{- template "sumologic.labels.app.otelcol" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.configmap" -}}
{{- template "sumologic.labels.app" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs" -}}
{{ template "sumologic.fullname" . }}-fluentd-logs
{{- end -}}

{{- define "sumologic.metadata.name.logs.headless" -}}
{{ template "sumologic.fullname" . }}-fluentd-logs-headless
{{- end -}}

{{- define "sumologic.metadata.name.logs.configmap" -}}
{{ template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.statefulset" -}}
{{ template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics" -}}
{{ template "sumologic.fullname" . }}-fluentd-metrics
{{- end -}}

{{- define "sumologic.metadata.name.metrics.headless" -}}
{{ template "sumologic.fullname" . }}-fluentd-metrics-headless
{{- end -}}

{{- define "sumologic.metadata.name.metrics.configmap" -}}
{{ template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.statefulset" -}}
{{ template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.events" -}}
{{ template "sumologic.fullname" . }}-fluentd-events
{{- end -}}

{{- define "sumologic.metadata.name.events.headless" -}}
{{ template "sumologic.fullname" . }}-fluentd-events-headless
{{- end -}}

{{- define "sumologic.metadata.name.events.configmap" -}}
{{ template "sumologic.metadata.name.events" . }}
{{- end -}}

{{- define "sumologic.metadata.name.events.statefulset" -}}
{{ template "sumologic.metadata.name.events" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelcol" -}}
{{ template "sumologic.fullname" . }}-otelcol
{{- end -}}

{{- define "sumologic.metadata.name.otelcol.configmap" -}}
{{ template "sumologic.metadata.name.otelcol" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelcol.deployment" -}}
{{ template "sumologic.metadata.name.otelcol" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup" -}}
{{ template "sumologic.fullname" . }}-setup
{{- end -}}

{{- define "sumologic.metadata.name.setup.configmap" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.labels.logs" -}}
sumologic/app: fluentd-logs
sumologic/component: logs
{{- end -}}

{{- define "sumologic.labels.metrics" -}}
sumologic/app: fluentd-metrics
sumologic/component: metrics
{{- end -}}

{{- define "sumologic.labels.events" -}}
sumologic/app: fluentd-events
sumologic/component: events
{{- end -}}

{{- define "sumologic.labels.traces" -}}
sumologic/app: otelcol
sumologic/component: traces
{{- end -}}

{{/*
Create common labels used throughout the chart.
If dryRun=true, we do not create any chart labels.
*/}}
{{- define "sumologic.labels.common" -}}
{{- if .Values.dryRun -}}
{{- else -}}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: "{{ .Release.Name }}"
heritage: "{{ .Release.Service }}"
{{- end -}}
{{- end -}}

{{/*
Returns sumologic version string
*/}}
{{- define "sumologic.sumo_client" -}}
k8s_{{ .Chart.Version }}
{{- end -}}

{{/*
Returns clusterName with spaces replaced with dashes
*/}}
{{- define "sumologic.clusterNameReplaceSpaceWithDash" -}}
{{ .Values.sumologic.clusterName | replace " " "-"}}
{{- end -}}

{{/*
Get configuration value, otherwise returns default

Example usage:

{{ include "utils.get_default" (dict "Values" .Values "Keys" (list "key1" "key2") "Default" "default_value") | quote }}

It returns `.Value.key1.key2` if it exists otherwise `default_value`

*/}}
{{- define "utils.get_default" -}}
{{- $dict := .Values -}}
{{- $keys := .Keys -}}
{{- $default := .Default -}}
{{- $success := true }}
{{- range $keys -}}
  {{- if (and $success (hasKey $dict .)) }}
    {{- $dict = index $dict . }}
  {{- else }}
    {{- $success = false }}
  {{- end }}
{{- end }}
{{- if $success }}
  {{- $dict }}
{{- else }}
  {{- $default }}
{{- end }}
{{- end -}}

{{/*
Generate metrics match configuration

Example usage (as one line):

{{ include "utils.metrics.match" (dict 
  "Values" .Values 
  "Match" "prometheus.metrics.kubelet" 
  "Endpoint" "SUMO_ENDPOINT_METRICS" 
  "Storage" .Values.fluentd.buffer.filePaths.metrics.default
  "Id" sumologic.endpoint.metrics
)}}
*/}}
{{- define "utils.metrics.match" -}}
<match {{ .Match }}>
  @type sumologic
  @id {{ .Id }}
  endpoint "#{ENV['{{ .Endpoint }}']}"
{{- .Values.fluentd.metrics.outputConf | nindent 2 }}
  <buffer>
    {{- if or .Values.fluentd.persistence.enabled (eq .Values.fluentd.buffer.type "file") }}
    @type file
    path {{ .Storage }}
    {{- else }}
    @type memory
    {{- end }}
    @include buffer.output.conf
  </buffer>
</match>
{{- end -}}