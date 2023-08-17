# Kubernetes Collection `v4.0.0` - Breaking Changes

<!-- TOC -->

- [Kubernetes Collection v4.0.0 - Breaking Changes](#kubernetes-collection-v400---breaking-changes)
  - [Important changes](#important-changes)
    - [OpenTelemetry Collector](#opentelemetry-collector)
  - [How to upgrade](#how-to-upgrade)
    - [Requirements](#requirements)
    - [Metrics migration](#metrics-migration)
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

### OpenTelemetry Collector

The new version replaces both Fluentd and Fluent Bit with the OpenTelemetry Collector. In the majority of cases, this doesn't require any
manual intervention. However, custom processing in Fluentd or Fluent Bit will need to be ported to the OpenTelemetry Collector configuration
format. Please check [Solution Overview][solution-overview] and see below for details.

[solution-overview]: /docs/README.md#solution-overview

### Drop Prometheus recording rule metrics

OpenTelemetry can't collect Prometheus recording rule metrics. The new version therefore stops collecting recording rule metrics and updates
will be made to the Kubernetes App to remove these metrics.

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

:construction:

### Removing support for Fluent Bit and Fluentd

Te following changes are required in order to switch to OpenTelemetry:

- `fluent-bit.*` has to be removed from `user-values.yaml`
- `sumologic.logs.collector.allowSideBySide` should be removed from `user-values.yaml`
- `sumologic.logs.defaultFluentd.*` should be removed from `user-values.yaml`
- `fluentd.*` should be removed from `user-values.yaml`
- `sumologic.logs.metadata.provider` should be removed from `user-values.yaml`
- `sumologic.metrics.metadata.provider` should be removed from `user-values.yaml`

#### Configuration Migration

In order to migrate your custom configuration, please carefully read and apply to your needs the following documents:

- [Collecting Container Logs](./collecting-container-logs.md)
- [Collecting Application Metrics](./collecting-application-metrics.md)
- [Collecting Kubernetes Events](./collecting-kubernetes-events.md)
- [Collecting Kubernetes Metrics](./collecting-kubernetes-metrics.md)

In addition the following changes has been done:

- `otelevents.serviceLabels` has been introduced as replacement for `fluentd.serviceLabels` for events service
- `sumologic.events.sourceName` is going to be used instead of `fluentd.events.sourceName` to build `_sourceCategory` for events

### Switch to OTLP sources

:construction:

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
