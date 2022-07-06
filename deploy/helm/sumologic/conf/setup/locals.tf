locals {
{{- $ctx := .Values }}
{{- range $type, $sources := .Values.sumologic.collector.sources }}
  {{- if eq (include "terraform.sources.component_enabled" (dict "Values" $ctx "Type" $type)) "true" }}
    {{- range $key, $source := $sources }}
      {{- if eq (include "terraform.sources.to_create" (dict "Context" $ctx "Type" $type "Name" $key)) "true" }}
  {{ template "terraform.sources.local" (dict "Name" (include "terraform.sources.name" (dict "Name" $key "Type" $type)) "Value" $source.name) }}
      {{- end }}
    {{- end }}
  {{- else if and (eq $type "metrics") $ctx.sumologic.traces.enabled }}
    {{- /*
    If traces are enabled and metrics are disabled, create default metrics source anyway
    */}}
    {{- if hasKey $sources "default" }}
  {{ template "terraform.sources.local" (dict "Name" (include "terraform.sources.name" (dict "Name" "default" "Type" $type)) "Value" ( dig "default" "name" "(default-metrics)" $sources )) }}
    {{- end }}
  {{- end }}
{{- end }}
}
