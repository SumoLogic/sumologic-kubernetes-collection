resource "sumologic_collector" "collector" {
    name  = var.collector_name
    description = format("Sumo Logic Kubernetes Collection\nversion: %s", var.chart_version)
    fields  = var.collector_fields
}

resource "kubernetes_secret" "sumologic_collection_secret" {
  metadata {
    name = var.secret_name
    namespace = var.namespace_name
  }

  data = {
    for name, config in local.source_configs : config["config-name"] => lookup(local.sources, name).url
  }

  type = "Opaque"
}
