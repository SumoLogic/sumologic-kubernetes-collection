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
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}

{{/*
Create default fully qualified labels.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sumologic.labels.app" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.clusterrole" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.clusterrolebinding" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.fluentd" -}}
{{- template "sumologic.fullname" . }}-fluentd
{{- end -}}

{{- define "sumologic.labels.app.logs" -}}
{{- template "sumologic.labels.app.fluentd" . }}-logs
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

{{- define "sumologic.labels.app.metrics" -}}
{{- template "sumologic.labels.app.fluentd" . }}-metrics
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

{{- define "sumologic.labels.app.events" -}}
{{- template "sumologic.labels.app.fluentd" . }}-events
{{- end -}}

{{- define "sumologic.labels.app.events.pod" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.events.service" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.events.service-headless" -}}
{{- template "sumologic.labels.app.events.service" . }}-headless
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

{{- define "sumologic.labels.app.otelcol.pod" -}}
{{- template "sumologic.labels.app.otelcol" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcol.service" -}}
{{- template "sumologic.labels.app.otelcol" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcol.configmap" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcol.deployment" -}}
{{- template "sumologic.labels.app.otelcol" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelagent" -}}
{{- template "sumologic.fullname" . }}-otelagent
{{- end -}}

{{- define "sumologic.labels.app.otelagent.pod" -}}
{{- template "sumologic.labels.app.otelagent" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelagent.service" -}}
{{- template "sumologic.labels.app.otelagent" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelagent.configmap" -}}
{{- template "sumologic.labels.app.otelagent" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelagent.daemonset" -}}
{{- template "sumologic.labels.app.otelagent" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelagent.component" -}}
{{- template "sumologic.labels.app.otelagent" . }}-component
{{- end -}}


{{- define "sumologic.labels.app.setup" -}}
{{- template "sumologic.labels.app" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.job" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.configmap" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.configmap-custom" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.clusterrole" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.clusterrolebinding" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.serviceaccount" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-setup-scc
{{- end -}}

{{- define "sumologic.labels.app.podsecuritypolicy" -}}
{{- template "sumologic.fullname" . }}-psp
{{- end -}}

{{- define "sumologic.labels.app.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-scc
{{- end -}}

{{- define "sumologic.labels.app.cleanup" -}}
{{- template "sumologic.labels.app" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.configmap" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.clusterrole" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.clusterrolebinding" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.serviceaccount" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.machineconfig.worker" -}}
{{- template "sumologic.fullname" . }}-worker-extensions
{{- end -}}

{{- define "sumologic.labels.machineconfig.worker" -}}
machineconfiguration.openshift.io/role: worker
{{- end -}}

{{- define "sumologic.labels.app.machineconfig.master" -}}
{{- template "sumologic.fullname" . }}-master-extensions
{{- end -}}

{{- define "sumologic.labels.machineconfig.master" -}}
machineconfiguration.openshift.io/role: master
{{- end -}}

{{/*
Generate cleanup job helm.sh annotations. It takes weight as parameter.

Example usage:

{{ include "sumologic.annotations.app.cleanup.helmsh" "1" }}

*/}}
{{- define "sumologic.annotations.app.cleanup.helmsh" -}}
helm.sh/hook: pre-delete
helm.sh/hook-weight: {{ printf "\"%s\"" . }}
helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
{{- end -}}

{{/*
Generate setup job helm.sh annotations. It takes weight as parameter.

Example usage:

{{ include "sumologic.annotations.app.setup.helmsh" "1" }}

*/}}
{{- define "sumologic.annotations.app.setup.helmsh" -}}
helm.sh/hook: pre-install,pre-upgrade
helm.sh/hook-weight: {{ printf "\"%s\"" . }}
helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
{{- end -}}

{{- define "sumologic.metadata.name.roles.clusterrole" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.roles.clusterrolebinding" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.podsecuritypolicy" -}}
{{ template "sumologic.fullname" . }}-psp
{{- end -}}

{{- define "sumologic.metadata.name.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-scc
{{- end -}}

{{- define "sumologic.metadata.name.fluentd" -}}
{{ template "sumologic.fullname" . }}-fluentd
{{- end -}}

{{- define "sumologic.metadata.name.logs" -}}
{{- if eq .Values.sumologic.logs.provider "fluentd" -}}
{{ template "sumologic.metadata.name.fluentd" . }}-logs
{{- else if eq .Values.sumologic.logs.provider "otelcol" -}}
{{ template "sumologic.metadata.name.otelcol" . }}-logs
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.logs.service" -}}
{{ template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.service-headless" -}}
{{ template "sumologic.metadata.name.logs.service" . }}-headless
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

{{- define "sumologic.metadata.name.metrics" -}}
{{ template "sumologic.metadata.name.fluentd" . }}-metrics
{{- end -}}

{{- define "sumologic.metadata.name.metrics.service" -}}
{{ template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.service-headless" -}}
{{ template "sumologic.metadata.name.metrics.service" . }}-headless
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

{{- define "sumologic.metadata.name.events" -}}
{{ template "sumologic.metadata.name.fluentd" . }}-events
{{- end -}}

{{- define "sumologic.metadata.name.events.service" -}}
{{ template "sumologic.metadata.name.events" . }}
{{- end -}}

{{- define "sumologic.metadata.name.events.service-headless" -}}
{{ template "sumologic.metadata.name.events.service" . }}-headless
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

{{- define "sumologic.metadata.name.otelcol.service" -}}
{{ template "sumologic.metadata.name.otelcol" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelcol.configmap" -}}
{{ template "sumologic.metadata.name.otelcol" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelcol.deployment" -}}
{{ template "sumologic.metadata.name.otelcol" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelagent" -}}
{{ template "sumologic.fullname" . }}-otelagent
{{- end -}}

{{- define "sumologic.metadata.name.otelagent.service" -}}
{{ template "sumologic.metadata.name.otelagent" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelagent.configmap" -}}
{{ template "sumologic.metadata.name.otelagent" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelagent.daemonset" -}}
{{ template "sumologic.metadata.name.otelagent" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup" -}}
{{ template "sumologic.fullname" . }}-setup
{{- end -}}

{{- define "sumologic.metadata.name.setup.job" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.configmap-custom" -}}
{{ template "sumologic.metadata.name.setup" . }}-custom
{{- end -}}

{{- define "sumologic.metadata.name.setup.configmap" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.clusterrole" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.clusterrolebinding" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.serviceaccount" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.securitycontextconstraints" -}}
{{- template "sumologic.metadata.name.setup" . }}-scc
{{- end -}}

{{- define "sumologic.metadata.name.cleanup" -}}
{{ template "sumologic.fullname" . }}-cleanup
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.configmap" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.clusterrole" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.clusterrolebinding" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.serviceaccount" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.logs" -}}
sumologic.com/app: fluentd-logs
sumologic.com/component: logs
{{- end -}}

{{- define "sumologic.labels.metrics" -}}
sumologic.com/app: fluentd-metrics
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.labels.events" -}}
sumologic.com/app: fluentd-events
sumologic.com/component: events
{{- end -}}

{{- define "sumologic.labels.traces" -}}
sumologic.com/app: otelcol
sumologic.com/component: traces
{{- end -}}

{{- define "sumologic.label.scrape" -}}
sumologic.com/scrape: "true"
{{- end -}}

{{- define "sumologic.labels.scrape.logs" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.logs" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.metrics" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.events" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.events" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.traces" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.traces" . }}
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
  "Values" . 
  "Tag" "prometheus.metrics.kubelet" 
  "Endpoint" "SUMO_ENDPOINT_METRICS" 
  "Storage" .Values.fluentd.buffer.filePaths.metrics.default
  "Id" sumologic.endpoint.metrics
)}}
*/}}
{{- define "utils.metrics.match" -}}
<match {{ .Tag }}>
  @type copy
  <store>
{{- if .Drop }}
    @type null
{{- else }}
    @type sumologic
    @id {{ .Id }}
    sumo_client {{ include "sumologic.sumo_client" .Context | quote }}
    endpoint "#{ENV['{{ include "terraform.sources.endpoint" .Endpoint}}']}"
{{- .Context.Values.fluentd.metrics.outputConf | nindent 2 }}
    <buffer>
      {{- if or .Context.Values.fluentd.persistence.enabled (eq .Context.Values.fluentd.buffer.type "file") }}
      @type file
      path {{ .Storage }}
      {{- else }}
      @type memory
      {{- end }}
      @include buffer.output.conf
    </buffer>
{{- end }}
  </store>
  {{- if .Context.Values.fluentd.monitoring.output }}
  {{ include "fluentd.prometheus-metrics.output" . | nindent 2 }}
  {{- end }}
</match>
{{ end -}}

{{/*
Generate fluentd prometheus filter configuration (input metrics)

Example:

{{ template "fluentd.prometheus-metrics.input" (dict "Tag" "kubernetes.**") }}
*/}}
{{- define "fluentd.prometheus-metrics.input" }}
<filter {{ .Tag }}>
  @type prometheus
  <metric>
    name fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</filter>
{{- end -}}

{{/*
Generate fluentd prometheus store configuration (output metrics)

Example:

{{ template "fluentd.prometheus-metrics.output" . }}
*/}}
{{- define "fluentd.prometheus-metrics.output" -}}
<store>
  @type prometheus
  <metric>
    name fluentd_output_status_num_records_total
    type counter
    desc The total number of outgoing records
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</store>
{{- end -}}

{{/*
Returns the name of Kubernetes secret.

Example usage:

{{ include "terraform.secret.name" }}

*/}}
{{- define "terraform.secret.name" -}}
{{ printf "%s" "sumologic" }}
{{- end -}}

{{/*
Returns the name of Kubernetes secret prefixed with release namespace.

Example usage:

{{ include "terraform.secret.fullname" }}

*/}}
{{- define "terraform.secret.fullname" -}}
{{ .Release.Namespace }}/{{ template "terraform.secret.name" . }}
{{- end -}}

{{/*
Convert source name to Terraform metric name:
 * converts all `-` to `_`
 * adds `_$type_source` suffix

Example usage:

{{ include "terraform.sources.name" $source }}

*/}}
{{- define "terraform.sources.name" -}}
{{ printf "%s_%s_source" (replace "-" "_" .Name) .Type }}
{{- end -}}

{{/*
Generate endpoint variable string for given string

Example usage:

{{ include "terraform.sources.endpoint" "logs" }}

*/}}
{{- define "terraform.sources.endpoint" -}}
SUMO_ENDPOINT_{{ replace "-" "_" . | upper }}
{{- end -}}

{{/*
Generate endpoint variable string for given string

Example usage:

{{ include "terraform.sources.endpoint" "logs" }}

*/}}
{{- define "terraform.sources.endpoint_name" -}}
{{ printf "endpoint-%s" . }}
{{- end -}}

{{/*
Generate line for local Terraform section
 * `terraform.sources.local = value`

Example usage:

{{ include "terraform.sources.local" $source }}

*/}}
{{- define "terraform.sources.local" -}}
{{ printf "%-43s = \"%s\"" .Name .Value }}
{{- end -}}

{{/*
Generate line for data Terraform section

Example usage:

{{ include "terraform.sources.data" (dict "Endpoint" "enpoint-default-metrics" "Name" "default") }}

*/}}
{{- define "terraform.sources.data" -}}
{{ printf "%-41s = sumologic_http_source.%s.url" .Endpoint .Name }}
{{- end -}}

{{/*
Returns the collector name.

Example usage:

{{ include "terraform.collector.name" . }}

*/}}
{{- define "terraform.collector.name" -}}
{{- if .Values.sumologic.collectorName }}{{ .Values.sumologic.collectorName }}{{- else}}{{ .Values.sumologic.clusterName }}{{- end}}
{{- end -}}

{{/*
Generate resource sections

Example usage:

{{ include "terraform.sources.resource" (dict "Source" $source "Context" $ctx) }}

*/}}
{{- define "terraform.sources.resource" -}}
{{- $source := .Source -}}
{{- $ctx := .Context -}}
resource "sumologic_http_source" "{{ .Name }}" {
    name         = local.{{ .Name }}
    collector_id = sumologic_collector.collector.id
    {{- if $source.properties }}
    {{- range $fkey, $fvalue := $source.properties }}
    {{- include "terraform.generate-object" (dict "Name" $fkey "Value" $fvalue "KeyLength" (include "terraform.max-key-length" $source.properties) "Indent" 2) -}}
    {{- end -}}
    {{- end }}
}
{{- end -}}

{{- define "terraform.max-key-length" -}}
{{- $max := 0 -}}
{{- range $key, $value := . -}}
{{- if gt (len $key) $max -}}
{{- $max = (len $key) -}}
{{- end -}}
{{- end -}}
{{ $max }}
{{- end -}}

{{/*
Generate key for Terraform object. Default behaviour is to print:

{{ name }} = {{ value }}

If this is key for list, prints only value.

This template takes care about indentation using Indent key

Example usage:

{{- include "terraform.generate-object" (dict "Name" "my_key" "Value" "my_value" "Indent" 8 "List" true) }}
*/}}
{{- define "terraform.generate-key" -}}
{{- $indent := int .Indent -}}
{{- $name := .Name -}}
{{- $keyLength := int .KeyLength -}}
{{- $format := printf "%%-%ss" (toString $keyLength) -}}
{{- $value := .Value -}}
{{- if and ( eq (kindOf $value) "string") (not .SkipEscaping) -}}
{{- $value = printf "\"%s\"" $value -}}
{{- end -}}
{{- if .SkipPadding -}}
{{- $format = "%s" -}}
{{- end -}}
{{ indent (int $indent) "" }}{{ if not .SkipName }}{{ printf $format (toString $name) }} {{ if not .SkipEqual }}= {{ end }}{{ end }}{{ (toString $value) }}{{ if .AddComma }},{{ end }}
{{- end -}}

{{/*
Generates Terraform object for primitives, slices and maps

Example usage:

{{- include "terraform.generate-object" (dict "Name" $name "Value" $value "Indent" 12 "List" true) }}

where:
  - Value can be slice, map or primitive type (int, string, etc)
  - Name is string
  - Indent should be convertable to int (0 by default)
  - List - information if the Value is element of the list, false by default
*/}}
{{- define "terraform.generate-object" -}}
{{- $name := .Name -}}
{{- $value := .Value -}}
{{- $keyLength := .KeyLength -}}
{{- $indent := int .Indent -}}
{{- $indent = add $indent 2 -}}
{{- $process := true -}}
{{- if eq (kindOf $value) "slice" }}
{{- range $sname, $svalue := $value }}
{{- if eq (kindOf $svalue) "map" }}
{{- $process = false }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" "{" "SkipPadding" true "SkipEqual" true "SkipEscaping" true "KeyLength" $keyLength "Indent" $indent) }}
{{- range $tname, $tvalue := $svalue }}
{{- include "terraform.generate-object" (dict "Name" $tname "Value" $tvalue "Indent" $indent "KeyLength" (include "terraform.max-key-length" $svalue)) }}
{{- end }}
{{ printf "}" | indent (int $indent) }}
{{- end }}
{{- end }}
{{- if $process }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" "[" "SkipPadding" true "SkipEscaping" true "KeyLength" $keyLength "Indent" $indent) }}
{{- range $sname, $svalue := $value }}
{{ include "terraform.generate-key" (dict "Name" $sname "Value" $svalue "SkipName" true "AddComma" true "Indent" (add $indent 2)) }}
{{- end }}
{{ printf "]" | indent (int $indent) }}
{{- end }}
{{- else if eq (kindOf $value) "map" }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" "{" "SkipPadding" true "SkipEscaping" true "KeyLength" $keyLength "Indent" $indent) }}
{{- range $sname, $svalue := $value }}
{{- include "terraform.generate-object" (dict "Name" $sname "Value" $svalue "KeyLength" (include "terraform.max-key-length" $value) "Indent" $indent) }}
{{- end }}
{{ printf "}" | indent (int $indent) }}
{{- else }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" $value "KeyLength" $keyLength "Indent" $indent) }}
{{- end -}}
{{- end -}}

{{/*
get configuration variable name for sources confg map

Example usage:

{{ include "terraform.sources.config-map-variable" (dict "Context" .Values "Name" $name "Endpoint" $endpoint) }}

*/}}
{{- define "terraform.sources.config-map-variable" -}}
{{- $name := .Name -}}
{{- $ctx := .Context -}}
{{- $type := .Type -}}
{{- $endpoint := .Endpoint -}}
{{- if not $endpoint -}}
{{- $source := (index $ctx.sumologic.collector.sources $type "default") -}}
{{- if (index $ctx.sumologic.collector.sources $type .Name "config-name") -}}
{{- $endpoint = index $ctx.sumologic.collector.sources $type .Name "config-name" -}}
{{- else -}}
{{- $endpoint = printf "endpoint-%s" (include "terraform.sources.name" (dict "Name" $name "Type" $type)) -}}
{{- end -}}
{{- end -}}
{{ $endpoint }}
{{- end -}}

{{/*
Add or skip quotation denending on the value

Examples:
  - "${test}" will be printed as `test`
  - "test" will be printed as `"test"`

Example Usage:
{{ include "terraform.sources.config-map-variable" "${file(\"/var/test\")}" }}

*/}}
{{- define "terraform.print_value" -}}
{{- if and (kindIs "string" .) -}}
{{- if (regexMatch "^\\$\\{[^\\$]*\\}$" .) -}}
{{ regexReplaceAll "^\\$\\{(.*)\\}$" . "${1}" }}
{{- else -}}
{{ printf "\"%s\"" . }}
{{- end -}}
{{- else -}}
{{ printf "\"%s\"" (toString .) }}
{{- end -}}
{{- end -}}

{{/*
Check if component (source/events/logs/traces etc.) is enabled or not

Example Usage:
{{- if eq (include "terraform.sources.component_enabled" (dict "Context" .Values "Type" "metrics")) "true" }}

*/}}
{{- define "terraform.sources.component_enabled" -}}
{{- $type := .Type -}}
{{- $ctx := .Context -}}
{{- $value := true -}}
{{- if hasKey $ctx.sumologic $type -}}
{{- if not (index $ctx.sumologic $type "enabled") -}}
{{- $value = false -}}
{{- end -}}
{{- end -}}
{{ $value }}
{{- end -}}

{{/*
Check if particular source is enabled or not

Example Usage:
{{- if eq (include "terraform.sources.to_create" (dict "Context" .Values "Type" "metrics" .Name "default" )) "true" }}

*/}}
{{- define "terraform.sources.to_create" -}}
{{- $type := .Type -}}
{{- $ctx := .Context -}}
{{- $name := .Name -}}
{{- $value := true -}}
{{- if and (hasKey $ctx.sumologic.collector.sources $type) (hasKey (index $ctx.sumologic.collector.sources $type) $name) (hasKey (index $ctx.sumologic.collector.sources $type $name) "create") -}}
{{- if not (index $ctx.sumologic.collector.sources $type $name "create") -}}
{{- $value = false -}}
{{- end -}}
{{- end -}}
{{ $value }}
{{- end -}}

{{/*
Generate fluentd envs for given source type:

Example:

{{ include "kubernetes.sources.envs" (dict "Context" .Values "Type" "metrics")}}
*/}}
{{- define "kubernetes.sources.envs" -}}
{{- $ctx := .Context -}}
{{- $type := .Type -}}
{{- range $key, $source := (index .Context.sumologic.collector.sources $type) }}
        - name: {{ template "terraform.sources.endpoint" (include "terraform.sources.name" (dict "Name" $key "Type" $type)) }}
          valueFrom:
            secretKeyRef:
              name: sumologic
              key: {{ template "terraform.sources.config-map-variable" (dict "Type" $type "Context" $ctx "Name" $key) }}
{{- end }}
{{- end -}}

{{/*
Generate a space separated list of quoted values:

Example:

{{ include "helm-toolkit.utils.joinListWithSpaces" .Values.sumologic.logs.fields }}
*/}}
{{- define "helm-toolkit.utils.joinListWithSpaces" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}
{{- if not $local.first }} {{ end -}}
{{- $v | quote -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}


{{/*
Returns kubernetes minor version as integer (without additional chars like +)

Example:

{{ include "kubernetes.minor" . }}
*/}}
{{- define "kubernetes.minor" -}}
{{- print (regexFind "^\\d+" .Capabilities.KubeVersion.Minor) -}}
{{- end -}}

{{- define "fluentd.metadata.annotations_match.quotes" -}}
{{- $matches_with_quotes := list -}}
{{- range $match := .Values.fluentd.metadata.annotation_match  }}
{{- $match_with_quotes := printf "\"%s\"" $match }}
{{- $matches_with_quotes = append $matches_with_quotes $match_with_quotes }}
{{- end }}
{{- $matches_with_quotes_with_commas := join "," $matches_with_quotes }}
{{- $annotations_match := list $matches_with_quotes_with_commas }}
{{- print $annotations_match }}
{{- end -}}


{{/*
Return k8s.cluster.name for opentelemetry collector

Example:

{{ include "otelcol.k8s.cluster.name" . }}
*/}}
{{- define "otelcol.k8s.cluster.name" -}}
{{ .Values.sumologic.collectorName | default .Values.sumologic.clusterName | quote }}
{{- end -}}


{{/*
Returns list of namespaces to exclude

Example:

{{ include "fluentd.excludeNamespaces" . }}
*/}}
{{- define "fluentd.excludeNamespaces" -}}
{{- $excludeNamespaceRegex := .Values.fluentd.logs.containers.excludeNamespaceRegex | quote -}}
{{- if eq .Values.sumologic.collectionMonitoring false -}}
  {{- $excludeNamespaceRegex = printf "%s|%s" .Release.Namespace .Values.fluentd.logs.containers.excludeNamespaceRegex | quote }}
{{- end -}}
{{ print $excludeNamespaceRegex }}
{{- end -}}


{{/*
Check if any logs provider is enabled

Example Usage:
{{- if eq (include "logs.enabled" .) "true" }}

*/}}
{{- define "logs.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.logs.enabled true -}}
{{- if and (eq .Values.sumologic.logs.provider "fluentd") (eq .Values.fluentd.logs.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- if and (eq .Values.sumologic.logs.provider "otelcol") (eq .Values.otelcol.logs.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}
