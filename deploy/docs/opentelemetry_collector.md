# Opentelemetry Collector

Opentelemetry Collector is a software to receive, process and export logs, metrics and traces.
We offer it as drop-in replacement for Fluentd in our collection.

**This feature is currently in beta and is not recommended for production environments.**

- [Metrics](#metrics)
  - [Metrics Configuration](#metrics-configuration)
- [Logs](#logs)
  - [Logs Configuration](#logs-configuration)

## Metrics

We are using Opentelemetry Collector like Fluentd to enrich metadata and to filter data.

To enable Opentelemetry Collector for metrics, please use the following configuration:

```yaml
sumologic:
  metrics:
    metadata:
      provider: otelcol
```

As we are providing drop-in replacement, most of the configuration from
[`values.yaml`][values] should work
the same way for Opentelemetry Collector like for Fluentd.

### Metrics Configuration

All Opentelemetry Collector configuration for metrics is located in
[`values.yaml`][values] as `metadata.metrics.config`.

If you want to modify it, please see [Sumologic Opentelemetry Collector configuration][configuration]
for more information.

## Logs

We are using Opentelemetry Collector like Fluentd to enrich metadata and to filter data.

To enable Opentelemetry Collector for logs, please use the following configuration:

```yaml
sumologic:
  logs:
    metadata:
      provider: otelcol
```

As we are providing drop-in replacement, most of the configuration from
[`values.yaml`][values] should work
the same way for Opentelemetry Collector like for Fluentd.

### Logs Configuration

All Opentelemetry Collector configuration for logs is located in
[`values.yaml`][values] as `metadata.logs.config`.

If you want to modify it, please see [Sumologic Opentelemetry Collector configuration][configuration]
for more information.

[configuration]: https://github.com/SumoLogic/sumologic-otel-collector/blob/main/docs/Configuration.md
[values]: ../helm/sumologic/values.yaml
