# Comparison of Fluent Bit and OpenTelemetry Collector functionality

This document is intended to help migrate custom Fluent Bit configurations to the OpenTelemetry Collector.

## Do I need to do anything to migrate?

Our default OpenTelemetry configuration will automatically cover some of the usecases that required a custom Fluent Bit configuration. These
include:

- Different container runtimes

  OpenTelemetry Collector will automatically detect the format of and parse logs from different container runtimes. In particular, it will
  gracefully handle clusters running docker-shim and containerd in parallel on different Nodes, which is useful for migrations. If your
  modifications to the Fluent Bit config were only needed to deal with container runtime log formatting, you can use the default otel
  configuration.

- Multiline log parsing

  OpenTelemetry Collector handles multiline parsing the same way for all container runtimes. Multiline parsing is configured via the
  `sumologic.logs.multiline` section. See [here][otel_multiline] for more details.

### What if I've made changes beyond the above?

You'll need to migrate if you're doing anything truly custom. Typically, this would involve:

- collecting non-container logs
- using filters to parse logs in a specific way
- forwarding logs to destinations other than Sumo

We're going to briefly explain how log collection using the OpenTelemetry Collector works, and how to approach migrating your configuration.

## Log collection with the OpenTelemetry Collector

### Overview

OpenTelemetry Collector is configured by defining `components` and then assembling these into `pipelines`. There are three basic types of
components, and they have fairly direct analogues in Fluent Bit:

- `receivers` are similar to Fluent Bit `inputs`
- `exporters` are similar to Fluent Bit `outputs`
- `processors` are similar to Fluent Bit `filters`

`pipelines` don't have a direct analogue in the Fluent Bit world. In Fluent Bit, you decide which component applies to which record by using
the `Match` directive. In the OpenTelemetry Collector, you instead assemble components into a pipeline directly. Pipelines can have multiple
receivers and exporters, but they can't have conditional processors - all the processors in a pipeline always apply.

You can read more about the OpenTelemetry Collector configuration format in the [official docs][otel_official_docs].

### Which components should I use for log collection?

For collecting logs from files: [filelog receiver][filelogreceiver] For modifying log records: [transform processor][transformprocessor] For
forwarding logs to various destinations: you need to pick the [right exporter][otel_distro_components]

### How do I add my custom configuration to the log collector?

The simplest way is to put it under the `otellogs.config.merge` key.

See [here][otel_config] for details and caveats.

[filelogreceiver]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/filelogreceiver
[transformprocessor]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/transformprocessor
[otel_distro_components]: https://github.com/SumoLogic/sumologic-otel-collector#components
[otel_official_docs]: https://opentelemetry.io/docs/collector/
[otel_multiline]: opentelemetry-collector.md#multiline-log-parsing
[otel_config]: opentelemetry-collector.md#logs-configuration
