resource "sumologic_collector" "collector" {
    name  = var.collector_name
    fields  = {
      {{- $fields := .Values.sumologic.setup.fields }}
      {{ include "terraform.generate-key" (dict "Name" "cluster" "Value" "var.cluster_name" "SkipEscaping" true "KeyLength" (include "terraform.max-key-length" $fields)) }}
      {{- range $name, $value := $fields }}
      {{ include "terraform.generate-key" (dict "Name" $name "Value" $value "KeyLength" (include "terraform.max-key-length" $fields)) }}
      {{- end}}
    }
}

{{- $ctx := .Values }}
{{- range $type, $sources := .Values.sumologic.sources }}
{{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
{{- range $key, $source := $sources }}
{{ include "terraform.sources.resource" (dict "Name" (include "terraform.sources.name" (dict "Name" $key "Type" $type)) "Source" $source "Context" $ctx) | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

resource "kubernetes_namespace" "sumologic_collection_namespace" {
  metadata {
    name = var.namespace_name
  }
}

resource "kubernetes_secret" "sumologic_collection_secret" {
  metadata {
    name = "sumologic"
    namespace = kubernetes_namespace.sumologic_collection_namespace.metadata[0].name
  }

  data = {
    {{- $ctx := .Values }}
    {{- range $type, $sources := .Values.sumologic.sources }}
    {{- if eq (include "terraform.sources.component_enabled" (dict "Context" $ctx "Type" $type)) "true" }}
    {{- range $key, $source := $sources }}
    {{ include "terraform.sources.data" (dict "Endpoint" (include "terraform.sources.config-map-variable" (dict "Type" $type "Context" $ctx "Name" $key)) "Name" (include "terraform.sources.name" (dict "Name" $key "Type" $type))) }}
    {{- end }}
    {{- end }}
    {{- end }}
  }

  type = "Opaque"
}
