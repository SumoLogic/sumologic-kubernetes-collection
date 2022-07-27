# Kubernetes Collection `v3.0.0` - Breaking Changes

- [Changes](#changes)
- [How to upgrade](#how-to-upgrade)

Based on the feedback from our users, we will be introducing several changes
to the Sumo Logic Kubernetes Collection solution.

In this document we detail the changes as well as the exact steps for migration.

## Changes

### OpenTelemetry Protocol sources

It is now possible to send data to Sumo Logic using the [OpenTelemetry Protocol][otlp]. The protocol is part of the new industry standard for processing and transporting observability data. When using the OpenTelemetry Collector, it's also more efficient, as
it avoids format conversions during serialization.

This is made possible by a new type of source, and the setup job will automatically
create these sources for each enabled data type. The OpenTelemetry Collector will then
send collected data to these sources instead of existing HTTP sources.

This shouldn't require any action, but please keep in mind that it will change some
of the metadata on ingested data - the `_source`, `_sourceId` and `_contenttype` fields
in particular. If you have any content like dashboards or monitors making use of these fields, you'll need to update them before upgrading the Helm Chart.

## How to upgrade

[otlp]: https://opentelemetry.io/docs/reference/specification/protocol/
