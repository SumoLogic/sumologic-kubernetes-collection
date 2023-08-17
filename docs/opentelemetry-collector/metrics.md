# Metrics

We are using OpenTelemetry Collector like Fluentd to enrich metadata and to filter data.

To enable OpenTelemetry Collector for metrics, please use the following configuration:

```yaml
sumologic:
  metrics:
    metadata:
      provider: otelcol
```

As we are providing drop-in replacement, most of the configuration from [`values.yaml`][values] should work the same way for OpenTelemetry
Collector like for Fluentd.

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
