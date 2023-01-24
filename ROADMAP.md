# Sumologic Kubernetes Collection Roadmap

## [Helm Chart v2][v2]

This version focuses on incorporating OpenTelemetry Collector as alternative for the following elements:

- logs collection
- events collection
- metadata enrichment for logs and metrics

## [Helm Chart v3][v3]

In this version Opentelemetry is going to be default choice for the following elements:

- logs collection
- events collection
- metadata enrichment for logs, events and metrics

We are going to deprecate Fluent Bit and Fluentd.

We are also aiming to use OpenTelemetry Collector as alternative to Prometheus.

## Helm Chart v4

Fluent Bit and Fluentd are going to be removed and no longer used.

Prometheus is going to be deprecated and replaced with OpenTelemetry Collector by default.

We are also going to move metadata enrichment closer to it's sources, e.g. for logs it's going to be performed by OpenTelemetry Collector
daemonset (node agent)

## Helm Chart v5

In this relase we would like to completely remove support for Prometheus.

[v2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2
[v3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/milestone/9
