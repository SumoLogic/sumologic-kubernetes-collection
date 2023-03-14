# Using the OTLP source

Historically, agents used by this Chart sent logs and metrics data to a [generic HTTP Source][http_source] in Sumo Logic. Ever since the
[version 3][v3] release, the Chart predominantly uses the [OpenTelemetry Collector][otel], and consequently also the [OTLP protocol][otlp].
The data needed to be converted to the formats the generic HTTP source supports before being sent.

Recently, we've added support for directly sending data using the OTLP protocol to Sumo Logic. This is achieved using the [OTLP
source][otlp_source]. This document explains how to use this new source with the Helm Chart.

**Note:** This Chart currently only supports OTLP Source for the following signal types: logs

## Enabling the OTLP source

Add the following to your configuration:

```yaml
sumologic:
  logs:
    sourceType: otlp
```

**Note:** The source is automatically created during Chart installation. This setting simply makes the Chart start sending data to it.

## Benefits

Sending data directly via OTLP is more efficient, as we skip the conversion step. OTLP is also a binary-encoded format, which improves the
efficiency further.

### Logs

As a structured log format, OTLP frees us from the need to parse metadata out of the log body on the Sumo side. This makes the following
features work without additional manual configuration:

- multiline parsing for the `text` log format
- correct timestamps for the `text` log format

[http_source]: https://help.sumologic.com/docs/send-data/hosted-collectors/http-source/logs-metrics/
[otlp_source]: https://help.sumologic.com/docs/send-data/hosted-collectors/http-source/otlp/
[v3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v3.0.0
[otel]: ./opentelemetry-collector.md
[otlp]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/otlp.md
