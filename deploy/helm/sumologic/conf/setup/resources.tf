resource "sumologic_collector" "collector" {
    name  = var.collector_name
    fields  = {
      {{- $fields := .Values.sumologic.collector.fields }}
      {{ include "terraform.generate-key" (dict "Name" "cluster" "Value" "var.cluster_name" "SkipEscaping" true "KeyLength" (include "terraform.max-key-length" $fields)) }}
      {{- range $name, $value := $fields }}
      {{ include "terraform.generate-key" (dict "Name" $name "Value" $value "KeyLength" (include "terraform.max-key-length" $fields)) }}
      {{- end}}
    }
}

{{- $ctx := .Values }}
{{- range $type, $sources := .Values.sumologic.collector.sources }}
{{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
{{- range $key, $source := $sources }}
{{- if eq (include "terraform.sources.to_create" (dict "Context" $ctx "Type" $type "Name" $key)) "true" }}
{{ include "terraform.sources.resource" (dict "Name" (include "terraform.sources.name" (dict "Name" $key "Type" $type)) "Source" $source "Context" $ctx) | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

resource "kubernetes_secret" "sumologic_collection_secret" {
  metadata {
    name = "{{ template "terraform.secret.name" }}"
    namespace = var.namespace_name
  }

  data = {
    {{- $ctx := .Values }}
    {{- range $type, $sources := .Values.sumologic.collector.sources }}
    {{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
    {{- range $key, $source := $sources }}
    {{- if eq (include "terraform.sources.to_create" (dict "Context" $ctx "Type" $type "Name" $key)) "true" }}
    {{ include "terraform.sources.data" (dict "Endpoint" (include "terraform.sources.config-map-variable" (dict "Type" $type "Context" $ctx "Name" $key)) "Name" (include "terraform.sources.name" (dict "Name" $key "Type" $type))) }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- end }}
  }

  type = "Opaque"
}
