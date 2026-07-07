resource "sumologic_collector" "collector" {
  count       = var.use_extension ? 0 : 1
  name        = var.collector_name
  description = format("Sumo Logic Kubernetes Collection\nversion: %s", var.chart_version)
  fields      = var.collector_fields
}

resource "sumologic_token" "collection_token" {
  count       = var.use_extension ? 1 : 0
  name        = format("kubernetes-collection-%s", var.collector_name)
  description = format("Installation token for Kubernetes Collection\nversion: %s", var.chart_version)
  type        = "CollectorRegistration"
  status      = "Active"
}

resource "kubernetes_secret" "sumologic_collection_secret" {
  metadata {
    name      = var.secret_name
    namespace = var.namespace_name
  }

  data = var.use_extension ? {
    "SUMOLOGIC_INSTALLATION_TOKEN" = sumologic_token.collection_token[0].encoded_token_and_url
  } : {
    for name, config in local.source_configs : config["config-name"] => lookup(local.sources, name).url
  }

  type                           = "Opaque"
  wait_for_service_account_token = false
}
