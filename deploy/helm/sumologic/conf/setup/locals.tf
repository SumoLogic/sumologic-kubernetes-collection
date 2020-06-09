locals {
{{- $ctx := .Values }}
{{- range $type, $sources := .Values.sumologic.sources }}
{{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
{{- range $key, $source := $sources }}
  {{ template "terraform.sources.local" (dict "Name" (include "terraform.sources.name" (dict "Name" $key "Type" $type)) "Value" $source.name) }}
{{- end }}
{{- end }}
{{- end }}
}
