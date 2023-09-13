# Logs

OpenTelemetry Collector is used for both log collection and metadata enrichment.

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

[values]: /deploy/helm/sumologic/values.yaml
