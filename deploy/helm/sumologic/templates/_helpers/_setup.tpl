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
{{ template "sumologic.namespace" . }}/{{ template "terraform.secret.name" . }}
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
{{- if eq (include "terraform.sources.component_enabled" (dict "Values" .Values "Type" "metrics")) "true" }}

*/}}
{{- define "terraform.sources.component_enabled" -}}
{{- $type := .Type -}}
{{- $ctx := .Values -}}
{{- $value := true -}}
{{- if hasKey $ctx.sumologic $type -}}
{{- if not (index $ctx.sumologic $type "enabled") -}}
{{- $value = false -}}
{{- end -}}
{{- end -}}
{{- if eq $type "events" -}}
{{ $value = include "events.enabled" . }}
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

{{- define "setup.job.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.sumologic.setup.job.nodeSelector)}}
{{- end -}}

{{- define "setup.job.tolerations" -}}
{{- if .Values.sumologic.setup.job.tolerations -}}
{{- toYaml .Values.sumologic.setup.job.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "setup.job.affinity" -}}
{{- if .Values.sumologic.setup.job.affinity -}}
{{- toYaml .Values.sumologic.setup.job.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}
