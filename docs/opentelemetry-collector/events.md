# Kubernetes Events

OpenTelemetry Collector is used to collect and enrich Kubernetes events.

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
