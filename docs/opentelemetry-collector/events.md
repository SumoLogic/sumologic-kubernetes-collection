# Kubernetes Events

OpenTelemetry Collector can be used to collect and enrich Kubernetes events instead of Fluentd. This is a drop-in replacement. To do this,
set the `sumologic.events.provider` to `otelcol`:

```yaml
sumologic:
  events:
    provider: otelcol
```

For configurations that don't modify `sumologic.fluentd.events.overrideOutputConf`, this should be enough. See the configuration options
under `otelevents` in [values.yaml](/deploy/helm/sumologic/values.yaml) for OT-specific configuration..

## Customizing OpenTelemetry Collector configuration

If the configuration options present under the `otelevents` key aren't sufficient for your needs, you can override the OT configuration
directly.

The `otelevents.config.merge` key can be used to provide configuration that will be merged with the Helm Chart's default configuration. It
should be noted that this field is not subject to normal backwards compatibility guarantees, the default configuration can change even in
minor versions while preserving the same end-to-end behaviour. Use of this field is discouraged - ideally the necessary customizations
should be able to be achieved without touching the otel configuration directly. Please open an issue if your use case requires the use of
this field.

The `otelevents.config.override` key can be used to provide configuration that will be completely replace the default configuration. As
above, care must be taken not to depend on implementation details that may change between minor releases of this Chart.
