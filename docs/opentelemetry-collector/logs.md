# Logs

OpenTelemetry Collector can be used for both log collection and metadata enrichment. For these roles, it replaces respectively Fluent Bit
and Fluentd.

For log collection, it can be enabled by setting:

```yaml
sumologic:
  logs:
    collector:
      otelcol:
        enabled: true

fluent-bit:
  enabled: false
```

> **NOTE** Normally, Fluent Bit must be disabled for OpenTelemetry Collector to be enabled. This restriction can be lifted, see
> [here](#running-otelcol-and-fluent-bit-side-by-side).

For metadata enrichment, it can be enabled by setting:

```yaml
sumologic:
  logs:
    metadata:
      provider: otelcol
```

If you haven't modified the Fluentd or Fluent Bit configuration, this should be a drop-in replacement with no further changes required.

## Logs Configuration

High level OpenTelemetry Collector configuration for logs is located in [`values.yaml`][values] under the `sumologic.logs` key.

Configuration specific to the log collector DaemonSet can be found under the `otellogs` key.

Finally, configuration specific to the metadata enrichment StatefulSet can be found under the `metadata.logs` key.

There are two ways of directly configuring OpenTelemetry Collector in either of these cases. These are both advanced features requiring a
good understanding of this chart's architecture and OpenTelemetry Collector configuration.

The `metadata.logs.config.merge` and `otellogs.config.merge` keys can be used to provide configuration that will be merged with the Helm
Chart's default configuration. It should be noted that this field is not subject to normal backwards compatibility guarantees, the default
configuration can change even in minor versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally
the necessary customizations should be able to be achieved without touching the otel configuration directly. Please open an issue if your
use case requires the use of this field.

The `metadata.logs.config.override` and `otellogs.config.override` keys can be used to provide configuration that will be completely replace
the default configuration. As above, care must be taken not to depend on implementation details that may change between minor releases of
this Chart.

### Multiline Log Parsing

Multiline log parsing for OpenTelemetry Collector can be configured using the `sumologic.logs.multiline` section in `user-values.yaml`.

```yaml
sumologic:
  logs:
    multiline:
      enabled: true
      first_line_regex: "^\\[?\\d{4}-\\d{1,2}-\\d{1,2}.\\d{2}:\\d{2}:\\d{2}"
```

where `first_line_regex` is a regular expression used to detect the first line of a multiline log.

### Container Logs

Container logs are collected by default. This can be disabled by setting:

```yaml
sumologic:
  logs:
    container:
      enabled: false
```

### SystemD Logs

Systemd logs are collected by default. This can be disabled by setting:

```yaml
sumologic:
  logs:
    systemd:
      enabled: false
```

It's also possible to change which SystemD units we want to collect logs from. For example, the below configuration only gets logs from the
Docker service:

```yaml
sumologic:
  logs:
    systemd:
      units:
        - docker.service
```

### Running otelcol and Fluent Bit side by side

Normally, enabling both Otelcol and Fluent-Bit for log collection will fail with an error. The reason for this is that doing so naively
results in each log line being delivered twice to Sumo Logic, incurring twice the cost without any benefit. However, there are reasons to do
this; for example it makes for a smoother and less risky migration. Advanced users may also want to pin the different collectors to
different Node groups.

Because of this, we've included a way to allow running otelcol and Fluent Bit side by side. The minimal configuration enabling this is:

```yaml
sumologic:
  logs:
    collector:
      otelcol:
        enabled: true
      allowSideBySide: true

fluent-bit:
  enabled: true
```

> **WARNING** Without further modifications to Otelcol and Fluent Bit configuration, this will cause each log line to be ingested twice,
> potentially doubling the cost of logs ingestion.

[values]: /deploy/helm/sumologic/values.yaml
