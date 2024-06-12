resource "sumologic_collector" "collector" {
    name  = var.collector_name
    description = {{ printf "Sumo Logic Kubernetes Collection\nversion: %s" .Chart.Version | quote }}
    fields  = {
      {{- $fields := .Values.sumologic.collector.fields }}
      {{- range $name, $value := $fields }}
      {{ include "terraform.generate-key" (dict "Name" $name "Value" $value "KeyLength" (include "terraform.max-key-length" $fields)) }}
      {{- end}}
    }
}

resource "kubernetes_secret" "sumologic_collection_secret" {
  metadata {
    name = "{{ template "terraform.secret.name" }}"
    namespace = var.namespace_name
  }

  data = {
    for name, config in local.source_configs : config["config-name"] => lookup(local.sources, name).url
  }

  type = "Opaque"
}
