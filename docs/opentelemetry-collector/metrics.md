# Metrics

We use the OpenTelemetry Collector for metrics in two ways:

- For metadata enrichment, where it replaces Fluentd.
- For metrics collection, where it replaces Prometheus.

These functionalities are currently independent of each other, and can be configured individually.

## Metrics collector

> [!NOTE]  
> This feature is currently in beta.

It's possible to use the OpenTelemetry Collector as a Prometheus replacement. To enable the otel metrics collector and disable Prometheus,
set:

```yaml
sumologic:
  metrics:
    collector:
      otelcol:
        enabled: true
    remoteWriteProxy:
      enabled: false

kube-prometheus-stack:
  prometheus:
    enabled: false
  prometheusOperator:
    enabled: false

opentelemetry-operator:
  enabled: true
```

This Otel metrics collector will function very similarly to Prometheus, and the change should be transparent for most configurations.

### Compatibility with the Prometheus ecosystem

The OpenTelemetry Collector is set up to be compatible with the Prometheus Kubernetes ecosystem. It supports ServiceMonitors and
PodMonitors, as well as plain Prometheus scrape configs. It also honors `prometheus.io/scrape` and related Pod annotations. As such, it
should be a drop-in replacement for Prometheus, with actual differences elaborated upon below.

### Differences from Prometheus

#### Horizontal scalability and autoscaling

The Otel metrics collector can be scaled horizontally, and consequently can also be autoscaled.

#### Improved performance

OpenTelemetry Collector consumes less memory and CPU for equivalent workloads. One can expect a 2x reduction in memory usage.

#### No recording rule metrics

The Otel metrics collector doesn't support recording rules. As the collector doesn't actually maintain a database of time series the way
Prometheus does, it cannot easily do aggregations over the whole dataset, or over longer time periods.

> [!WARNING]  
> Some of the Node-specific panels of the Sumo Kubernetes App will not work as a result of this. An update to the App will be released in
> the near future.

#### No extended features of the Prometheus ecosystem

OpenTelemetry collector is just a collector - it scrapes metrics data, transforms it, and forwards it to Sumo. It does not maintain a
database that can be queried and does not handle alerts.

### Configuration

Configuration keys for the Otel metrics collector live under the `sumologic.metrics.collector` section of the [values.yaml][values] file.
Configuration for ServiceMonitors elsewhere in the Chart will still apply.

## Metrics metadata

To enable OpenTelemetry Collector for metrics metadata, please use the following configuration:

```yaml
sumologic:
  metrics:
    metadata:
      provider: otelcol
```

As we are providing drop-in replacement, most of the configuration from [`values.yaml`][values] should work the same way for OpenTelemetry
Collector and for Fluentd.

## Metrics Configuration

There are two ways of directly configuring OpenTelemetry Collector for metrics metadata. These are both advanced features requiring a good
understanding of this chart's architecture and OpenTelemetry Collector configuration

The `metadata.metrics.config.merge` key can be used to provide configuration that will be merged with the Helm Chart's default
configuration. It should be noted that this field is not subject to normal backwards compatibility guarantees, the default configuration can
change even in minor versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally the necessary
customizations should be able to be achieved without touching the otel configuration directly. Please open an issue if your use case
requires the use of this field.

The `metadata.metrics.config.override` key can be used to provide configuration that will be completely replace the default configuration.
As above, care must be taken not to depend on implementation details that may change between minor releases of this Chart.

If you want to modify it, please see [Sumologic OpenTelemetry Collector configuration][configuration] for more information.

[configuration]: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/docs/configuration.md
[values]: /deploy/helm/sumologic/values.yaml
