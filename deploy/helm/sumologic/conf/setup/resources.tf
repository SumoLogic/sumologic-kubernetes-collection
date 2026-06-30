resource "sumologic_collector" "collector" {
  name        = var.collector_name
  description = format("Sumo Logic Kubernetes Collection\nversion: %s", var.chart_version)
  fields      = var.collector_fields
}

resource "sumologic_installation_token" "collection_token" {
  count       = var.use_extension ? 1 : 0
  name        = format("kubernetes-collection-%s", var.collector_name)
  description = format("Installation token for Kubernetes Collection\nversion: %s", var.chart_version)
  status      = "Active"
}

resource "kubernetes_secret" "sumologic_collection_secret" {
  metadata {
    name      = var.secret_name
    namespace = var.namespace_name
  }

  data = merge(
    # Source URL keys: all sources in normal mode; only traces + metrics/default in extension mode
    { for name, config in local.source_configs : config["config-name"] => lookup(local.sources, name).url },
    # Extension-specific keys: installation token and hosted collector ID
    var.use_extension ? {
      "SUMOLOGIC_INSTALLATION_TOKEN" = sumologic_installation_token.collection_token[0].token
      "SUMOLOGIC_COLLECTOR_ID"       = sumologic_collector.collector.id
    } : {}
  )

  type                           = "Opaque"
  wait_for_service_account_token = false
}
