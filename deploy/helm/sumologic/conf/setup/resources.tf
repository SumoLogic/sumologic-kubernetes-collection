resource "sumologic_collector" "collector" {
  count       = var.use_extension ? 0 : 1
  name        = var.collector_name
  description = format("Sumo Logic Kubernetes Collection\nversion: %s", var.chart_version)
  fields      = var.collector_fields
}

resource "sumologic_token" "collection_token" {
  count       = (var.use_extension && !var.provided_installation_token) ? 1 : 0
  name        = format("kubernetes-collection-%s", var.collector_name)
  description = format("Installation token for Kubernetes Collection\nversion: %s", var.chart_version)
  type        = "CollectorRegistration"
  status      = "Active"
}

resource "kubernetes_secret" "sumologic_collection_secret" {
  count = var.use_extension ? 0 : 1

  metadata {
    name      = var.secret_name
    namespace = var.namespace_name
  }

  data = tomap({
    for name, config in local.source_configs : config["config-name"] => lookup(local.sources, name).url
  })

  type                           = "Opaque"
  wait_for_service_account_token = false
}

# Only created when sourceless mode is on and no token was provided via Helm values.
# When installationToken is set in values, extension-secret.yaml owns this secret instead.
resource "kubernetes_secret" "extension_secret" {
  count = (var.use_extension && !var.provided_installation_token) ? 1 : 0

  metadata {
    name      = var.extension_secret_name
    namespace = var.namespace_name
  }

  data = tomap({
    "SUMOLOGIC_INSTALLATION_TOKEN" = sumologic_token.collection_token[0].encoded_token_and_url
  })

  type                           = "Opaque"
  wait_for_service_account_token = false
}
