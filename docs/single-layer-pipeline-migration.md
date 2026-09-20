# Single-Layer Metrics Pipeline Migration Guide

## Table of Contents

- [Overview](#overview)
- [What Changes](#what-changes)
- [Resource Sizing](#resource-sizing)
  - [Formula](#formula)
  - [Key Principles](#key-principles)
- [Configuration Migration](#configuration-migration)
  - [Automatic (No Action Needed)](#automatic-no-action-needed)
  - [Customer Action Required](#customer-action-required)
  - [Incompatible](#incompatible)
  - [Prometheus Remote Write](#prometheus-remote-write)
  - [Pipeline Rename: metrics/collector](#pipeline-rename-metricscollector)
- [How to Enable](#how-to-enable)
- [Rollback](#rollback)

## Overview

The Kubernetes metrics collection pipeline is moving from a **2-layer architecture** (collector StatefulSet + metadata StatefulSet) to a
**single-layer architecture** (collector only).

In the 2-layer pipeline:

- **Layer 1 (Collector)** scrapes metrics via the Prometheus receiver, applies light processing, and forwards via OTLP to Layer 2.
- **Layer 2 (Metadata)** enriches metrics with Kubernetes metadata (k8sattributes, source, sumologic processors), applies routing, batching,
  and exports to Sumo Logic.

In the single-layer pipeline, the collector handles all of this in a single pod using two logical pipelines connected by a `forward`
connector. The metadata StatefulSet, HPA, Services, and PDB are no longer rendered.

> **Note:** If you do not have any custom configs applied to your existing Sumo Logic Kubernetes Collection Helm chart (i.e., you are using
> the default values), you can skip the migration steps below and directly set
> `sumologic.metrics.collector.otelcol.singleLayerPipeline.enabled: true` and
> `sumologic.metrics.collector.otelcol.singleLayerPipeline.migrationDocAcknowledged: true` in your values file.

> **Note:** If it is not possible to migrate your metrics pipeline to single-layer at this time, you can disable it and continue using the
> existing 2-layer pipeline. See [Rollback](#rollback) for instructions.

### Benefits

- Fewer pods (metadata replicas eliminated), reducing resource consumption
- Lower end-to-end latency (no internal OTLP hop)
- Simpler configuration (single pipeline to reason about)

## What Changes

When `sumologic.metrics.collector.otelcol.singleLayerPipeline.enabled` is set to `true`:

1. The **metadata metrics StatefulSet, HPA, Services, and PDB are not rendered**
2. The **collector config** includes all enrichment processors (k8sattributes, source, sumologic, etc.) and Sumo Logic exporters
3. **SUMO_ENDPOINT\_\*** env vars are injected into the collector pod
4. Both `sumologic.metrics.collector.otelcol.config.merge` and `metadata.metrics.config.merge` are applied to the collector config,
   preserving existing customizations
5. The **collector pipeline is renamed** from `metrics` to `metrics/collector`. The enrichment pipeline keeps the name `metrics` (matching
   the 2-layer metadata pipeline name). See [Pipeline Rename](#pipeline-rename-metricscollector) under Configuration Migration.

## Resource Sizing

In single-layer mode, the collector handles both scraping and enrichment/export. You **must** increase collector resources.

### Formula

```
Single-layer memory limit = current collector memory limit + current metadata memory limit
Single-layer CPU limit    = current collector CPU limit + (total metadata CPU usage / number of collector replicas)
```

Apply a **1.5x safety multiplier** on memory to account for k8sattributes cache growth, queue buildup during backend slowdowns, and uneven
target distribution.

### Key Principles

- **Prefer higher limits over tighter limits.** An OOMKilled collector drops all in-flight metrics. Over-provisioning wastes some reserved
  memory but prevents production data loss.
- **CPU can be burstable.** CPU throttling slows processing but doesn't kill the pod. Setting CPU request lower than limit (e.g., request=2,
  limit=6) is acceptable.
- **Use HPA with memory target at 60-70%.** This gives headroom for spikes.
- **Monitor `container_memory_working_set_bytes`** after enabling single-layer. If any pod sustains >80% of its memory limit, increase the
  limit.

## Configuration Migration

### Automatic (No Action Needed)

These keys are consumed directly in the single-layer collector config template:

| Key                                       | Description                                        |
| ----------------------------------------- | -------------------------------------------------- |
| `metadata.metrics.logLevel`               | OTel Collector log verbosity                       |
| `metadata.metrics.metricsLevel`           | Internal metrics verbosity                         |
| `metadata.metrics.useSumoK8sProcessor`    | k8s_tagger vs k8sattributes processor selection    |
| `metadata.metrics.waitForMetadata`        | Wait for K8s API cache before processing           |
| `metadata.metrics.waitForMetadataTimeout` | Timeout for the above                              |
| `metadata.metrics.extractPodLabels`       | Extract pod labels as resource attributes          |
| `metadata.metrics.extractNodeLabels`      | Extract node labels as resource attributes         |
| `metadata.metrics.config.merge`           | Deep-merged into the single-layer collector config |

### Customer Action Required

These keys configure the metadata StatefulSet's scheduling, resources, and scaling. The collector has equivalent keys — you must move your
customizations:

| Metadata Key (No Longer Used)                                     | Collector Equivalent                                                                |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `metadata.metrics.statefulset.nodeSelector`                       | `sumologic.metrics.collector.otelcol.nodeSelector`                                  |
| `metadata.metrics.statefulset.tolerations`                        | `sumologic.metrics.collector.otelcol.tolerations`                                   |
| `metadata.metrics.statefulset.affinity`                           | `sumologic.metrics.collector.otelcol.affinity`                                      |
| `metadata.metrics.statefulset.replicaCount`                       | `sumologic.metrics.collector.otelcol.replicaCount`                                  |
| `metadata.metrics.statefulset.resources`                          | `sumologic.metrics.collector.otelcol.resources`                                     |
| `metadata.metrics.statefulset.priorityClassName`                  | `sumologic.metrics.collector.otelcol.priorityClassName`                             |
| `metadata.metrics.statefulset.podLabels`                          | `sumologic.metrics.collector.otelcol.podLabels`                                     |
| `metadata.metrics.statefulset.podAnnotations`                     | `sumologic.metrics.collector.otelcol.podAnnotations`                                |
| `metadata.metrics.statefulset.containers.otelcol.securityContext` | `sumologic.metrics.collector.otelcol.securityContext`                               |
| `metadata.metrics.autoscaling.enabled`                            | `sumologic.metrics.collector.otelcol.autoscaling.enabled`                           |
| `metadata.metrics.autoscaling.minReplicas`                        | `sumologic.metrics.collector.otelcol.autoscaling.minReplicas`                       |
| `metadata.metrics.autoscaling.maxReplicas`                        | `sumologic.metrics.collector.otelcol.autoscaling.maxReplicas`                       |
| `metadata.metrics.autoscaling.targetCPUUtilizationPercentage`     | `sumologic.metrics.collector.otelcol.autoscaling.targetCPUUtilizationPercentage`    |
| `metadata.metrics.autoscaling.targetMemoryUtilizationPercentage`  | `sumologic.metrics.collector.otelcol.autoscaling.targetMemoryUtilizationPercentage` |
| `metadata.metrics.autoscaling.behavior`                           | `sumologic.metrics.collector.otelcol.autoscaling.behavior`                          |
| `metadata.metrics.statefulset.extraEnvVars`                       | `sumologic.metrics.collector.otelcol.extraEnvVars`                                  |
| `metadata.metrics.statefulset.extraVolumes`                       | `sumologic.metrics.collector.otelcol.extraVolumes`                                  |
| `metadata.metrics.statefulset.extraVolumeMounts`                  | `sumologic.metrics.collector.otelcol.extraVolumeMounts`                             |

### Incompatible

| Key                                | Migration                                                                                                             |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `metadata.metrics.config.override` | Cannot be used with single-layer pipeline. Use `metadata.metrics.config.merge` instead, or disable single-layer mode. |

### Prometheus Remote Write

If you use `metadata.metrics.enableSumoPrometheusRemotewriteReceiver` to push metrics via Prometheus remote write, update the remote_write
URL hostname from `<release>-sumologic-metadata-metrics` to `<release>-sumologic-metrics-collector` (same port 9888, same path).

### Pipeline Rename: `metrics/collector`

In 2-layer mode, the collector has a single pipeline named `metrics`:

```yaml
# 2-layer collector config
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      processors: [filter/drop_stale_datapoints, ...]
      exporters: [otlphttp]
```

In single-layer mode, the collector has two logical pipelines connected by a `forward` connector:

```yaml
# Single-layer collector config
service:
  pipelines:
    metrics/collector: # scraping + light processing (was "metrics" in 2-layer)
      receivers: [prometheus]
      processors: [filter/drop_stale_datapoints, ...]
      exporters: [forward]
    metrics: # enrichment + export (same name as 2-layer metadata pipeline)
      receivers: [forward]
      processors: [memory_limiter, k8sattributes, source, sumologic, ...]
      exporters: [sumologic/default]
```

**Impact on `config.merge`:**

- **`metadata.metrics.config.merge`** targeting `service.pipelines.metrics` continues to work unchanged -- it hits the enrichment pipeline
  which has the same name and processor structure as the 2-layer metadata pipeline.
- **`sumologic.metrics.collector.otelcol.config.merge`** targeting `service.pipelines.metrics` will now target the **enrichment** pipeline,
  not the scraping pipeline. If your collector config.merge adds processors or modifies the scraping pipeline, update the pipeline reference
  from `metrics` to `metrics/collector`.

**Example migration:**

```yaml
# Before (2-layer): adds a processor to the collector's scraping pipeline
sumologic:
  metrics:
    collector:
      otelcol:
        config:
          merge:
            service:
              pipelines:
                metrics:
                  processors:
                    - my_custom_processor
                    - filter/drop_stale_datapoints

# After (single-layer): same processor, but targeting the renamed pipeline
sumologic:
  metrics:
    collector:
      otelcol:
        config:
          merge:
            service:
              pipelines:
                metrics/collector:
                  processors:
                    - my_custom_processor
                    - filter/drop_stale_datapoints
```

## How to Enable

1. **Review your current resource usage.** Check `container_memory_working_set_bytes` and CPU usage for both collector and metadata pods.

2. **Calculate new collector resource limits** using the formula above. Apply the 1.5x safety multiplier on memory.

3. **Migrate metadata configuration keys** from the table above to their collector equivalents.

4. **Run `helm upgrade`** and monitor collector pods for memory pressure.

## Rollback

To restore the 2-layer pipeline, set `singleLayerPipeline.enabled: false` in your values file and run `helm upgrade`. The metadata
StatefulSet, HPA, Services, and PDB will be re-created.

**PVC cleanup:** PVCs from the previous pipeline mode are not automatically deleted when switching between modes. After switching:

- **From 2-layer to single-layer:** The metadata StatefulSet PVCs (e.g., `file-storage-<release>-sumologic-otelcol-metrics-*`) are orphaned
  and must be manually deleted.
- **From single-layer to 2-layer:** The single-layer collector PVCs are orphaned and must be manually deleted.
