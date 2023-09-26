# Kubernetes Collection `v4.0.0` - Breaking Changes

<!-- TOC -->

- [Kubernetes Collection `v4.0.0` - Breaking Changes](#kubernetes-collection-v400---breaking-changes)
  - [Important changes](#important-changes)
    - [Remove Fluent Bit and Fluentd](#remove-fluent-bit-and-fluentd)
    - [Drop Prometheus recording rule metrics](#drop-prometheus-recording-rule-metrics)
    - [OpenTelemetry Collector for metrics collection](#opentelemetry-collector-for-metrics-collection)
    - [Use OTLP sources by default](#use-otlp-sources-by-default)
  - [How to upgrade](#how-to-upgrade)
    - [Requirements](#requirements)
    - [Metrics migration](#metrics-migration)
      - [Convert Prometheus remote writes to otel metrics filters](#convert-prometheus-remote-writes-to-otel-metrics-filters)
      - [How do I revert to the v3 defaults?](#how-do-i-revert-to-the-v3-defaults)
    - [Removing support for Fluent Bit and Fluentd](#removing-support-for-fluent-bit-and-fluentd)
      - [Configuration Migration](#configuration-migration)
    - [Switch to OTLP sources](#switch-to-otlp-sources)
    - [Running the helm upgrade](#running-the-helm-upgrade)
    - [Known issues](#known-issues)
  - [Full list of changes](#full-list-of-changes)

<!-- /TOC -->

Based on feedback from our users, we will be introducing several changes to the Sumo Logic Kubernetes Collection solution.

This document describes the major changes and the necessary migration steps.

## Important changes

### Remove Fluent Bit and Fluentd

As of version 3 of the Chart, Fluent Bit and Fluentd were replaced by the OpenTelemetry Collector by default. However, it was still possible
to use Fluent Bit and/or Fluentd by changing the configuration. In version 4 this is no longer possible. For migration instructions, see the
[v3 migration guide][v3_migration_guide].

### Drop Prometheus recording rule metrics

OpenTelemetry can't collect Prometheus recording rule metrics. The new version therefore stops collecting recording rule metrics and updates
will be made to the Kubernetes App to remove these metrics.

### OpenTelemetry Collector for metrics collection

By default, the OpenTelemetry Collector is now used for metrics collection instead of Prometheus. For the majority of use cases, this will
be a transparent change without any need for manual configuration changes. OpenTelemetry Collector will continue to collect the same default
metrics as Prometheus did previously, and will support the same mechanisms for collecting custom application metrics. Any exceptions will be
called out in the migration guide below.

### Use OTLP sources by default

This Helm Chart automatically creates the necessary Collector and Sources in Sumo. Up until this point, these were generic HTTP sources
accepting data in different formats. As Sumo now has native support for the OTLP protocol used by Open Telemetry, we've decided to switch to
using these new sources by default. This is a completely transparent change **unless** you use the `_sourceName` or `_source` fields in your
Sumo queries.

## How to upgrade

### Requirements

- `helm3`
- `kubectl`

Set the following environment variables that our commands will make use of:

```bash
export NAMESPACE=...
export HELM_RELEASE_NAME=...
```

### Metrics migration

If you don't have metrics collection enabled, skip straight to the [next major section](#switch-to-otlp-sources).

#### Convert Prometheus remote writes to otel metrics filters

**When?**: If you have custom remote writes defined in `kube-prometheus-stack.prometheus.additionalRemoteWrites`

When using Prometheus for metrics collection in v3, we relied on remote writes for filtering forwarded metrics. Otel, which is the default
in v4, does not support remote writes, so we've moved this functionality to Otel processors, or ServiceMonitors if it can be done there.

There are several scenarios here, depending on the exact use case:

1. You're collecting different [Kubernetes metrics][kubernetes_metrics_v3] than what the Chart provides by default. You've modified the
   existing ServiceMonitor for these metrics, and added a remote write as instructed by the documentation.

You can safely delete the added remote write definition. No further action is required.

1. As above, but you're also doing some additional data transformation via relabelling rules in the remote write definition.

You'll need to either move the relabelling rules into the ServiceMonitor itself, or [add an equivalent filter
processor][otel_metrics_filter] rule to Otel.

1. You're collecting custom application metrics by adding a [`prometheus.io/scrape` annotation][application_metrics_annotation]. You don't
   need to filter these metrics.

No action is needed.

1. As above, but you also have a remote write definition to filter these metrics.

You'll need to delete the remote write definition and [add an equivalent filter processor][otel_metrics_filter] rule to Otel.

#### How do I revert to the v3 defaults?

Set the following in your configuration:

```yaml
sumologic:
  metrics:
    collector:
      otelcol:
        enabled: false
    remoteWriteProxy:
      enabled: true

kube-prometheus-stack:
  prometheus:
    enabled: true
  prometheusOperator:
    enabled: true
```

### Removing support for Fluent Bit and Fluentd

Te following changes are required in order to switch to OpenTelemetry:

- `fluent-bit.*` has to be removed from `user-values.yaml`
- `sumologic.logs.collector.allowSideBySide` should be removed from `user-values.yaml`
- `sumologic.logs.defaultFluentd.*` should be removed from `user-values.yaml`
- `fluentd.*` should be removed from `user-values.yaml`
- `sumologic.logs.metadata.provider` should be removed from `user-values.yaml`
- `sumologic.metrics.metadata.provider` should be removed from `user-values.yaml`

#### Configuration Migration

Please see the [v3 migration guide][v3_migration_guide].

In addition the following changes have been made:

- `otelevents.serviceLabels` has been introduced as replacement for `fluentd.serviceLabels` for events service
- `sumologic.events.sourceName` is going to be used instead of `fluentd.events.sourceName` to build `_sourceCategory` for events

If you've changed the values of either of these two options, please adjust your configuration accordingly.

### Switch to OTLP sources

> [!NOTE] Both source types will be created by the setup job. The settings discussed here affect which source is actually used.

**When?**: You use the `_sourceName` or `_source` fields in your Sumo queries.

The only solution is to change the queries in question. In general, it's an antipattern to write queries against specific sources, instead
of semantic attributes of the data.

You can switch back to the default v3 behaviour by setting:

```yaml
sumologic:
  logs:
    sourceType: http

  metrics:
    sourceType: http

  traces:
    sourceType: http

  events:
    sourceType: http

tracesSampler:
  config:
    exporters:
      otlphttp:
        traces_endpoint: ${SUMO_ENDPOINT_DEFAULT_TRACES_SOURCE}/v1/traces
```

### Running the helm upgrade

Once you've taken care of any manual steps necessary for your configuration, run the helm upgrade:

```bash
helm upgrade --namespace "${NAMESPACE}" "${HELM_RELEASE_NAME}" sumologic/sumologic --version=4.0.0 -f new-values.yaml
```

After you're done, please review the [full list of changes](#full-list-of-changes), as some of them may impact you even if they don't
require additional action.

### Known issues

:construction:

## Full list of changes

- Drop Prometheus recording rule metrics

  OpenTelemetry can't collect Prometheus recording rule metrics. The new version therefore stops collecting the following recording rule
  metrics

  - kube_pod_info_node_count
  - node_cpu_saturation_load1
  - node_cpu_utilisation:avg1m
  - node_disk_saturation:avg_irate
  - node_disk_utilisation:avg_irate
  - node_memory_swap_io_bytes:sum_rate
  - node_memory_utilisation
  - node_net_saturation:sum_irate
  - node_net_utilisation:sum_irate
  - cluster_quantile:apiserver_request_duration_seconds:histogram_quantile
  - cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile
  - cluster_quantile:scheduler_framework_extension_point_duration_seconds:histogram_quantile
  - cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile
  - cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile
  - instance:node_network_receive_bytes:rate:sum
  - node:cluster_cpu_utilisation:ratio
  - node:cluster_memory_utilisation:ratio
  - node:node_cpu_saturation_load1
  - node:node_cpu_utilisation:avg1m
  - node:node_disk_saturation:avg_irate
  - node:node_disk_utilisation:avg_irate
  - node:node_filesystem_avail
  - node:node_filesystem_usage
  - node:node_inodes_free
  - node:node_inodes_total
  - node:node_memory_bytes_total:sum
  - node:node_memory_swap_io_bytes:sum_rate
  - node:node_memory_utilisation
  - node:node_memory_utilisation:ratio
  - node:node_memory_utilisation_2
  - node:node_net_saturation:sum_irate
  - node:node_net_utilisation:sum_irate
  - node:node_num_cpu:sum
  - node_namespace_pod:kube_pod_info

  Instead, the following new node metrics are now collected

  - node_disk_io_time_weighted_seconds_total
  - node_disk_io_time_seconds_total
  - node_vmstat_pgpgin
  - node_vmstat_pgpgout
  - node_memory_MemFree_bytes
  - node_memory_Cached_bytes
  - node_memory_Buffers_bytes
  - node_memory_MemTotal_bytes
  - node_network_receive_drop_total
  - node_network_transmit_drop_total
  - node_network_receive_bytes_total
  - node_network_transmit_bytes_total
  - node_filesystem_avail_bytes
  - node_filesystem_size_bytes

- Drop `k8s.node.name` attribute from metrics

  The `node` attribute exists and has the same value, so this is superfluous.

- Truncating full name to 22 characters

  Some Kubernetes objects, for example statefulsets, have a tight (63 characters) limit for their names. Because of that, we truncate the
  prefix that is attached to the names. In particular, the value under key `fullnameOverride` will be truncated to 22 characters.

- Moving extra processors in metrics pipeline after sumologic_schema processor

  This has been changed in order to make the behaviour consistent with the logs pipeline. Now, the extra processors should use [translated
  versions of some attributes][attribute_translation].

[application_metrics_annotation]: ./collecting-application-metrics.md#application-metrics-are-exposed-one-endpoint-scenario
[kubernetes_metrics_v3]:
  https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v3/docs/collecting-kubernetes-metrics.md#collecting-kubernetes-metrics
[otel_metrics_filter]: ./collecting-application-metrics.md#filtering-metrics
[v3_migration_guide]: ./v3-migration-doc.md
[attribute_translation]:
  https://github.com/SumoLogic/sumologic-otel-collector/tree/v0.85.0-sumo-0/pkg/processor/sumologicschemaprocessor#attribute-translation
