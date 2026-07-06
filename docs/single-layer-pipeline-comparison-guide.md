# Single-Layer Pipeline: Before vs After Comparison Guide

This document outlines the key metrics and parameters to measure when evaluating the impact of enabling `singleLayerPipeline` for metrics
collection. All comparisons should be made over the same time window (e.g., 24h) with equivalent workloads.

## 1. Data Correctness (Must-Have)

These metrics confirm that no data is being lost or duplicated.

### Metric Points Exported

```
_collector=<cluster> namespace=<ns> metric=otelcol_exporter_sent_metric_points statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | rate counter | sum by exporter
```

**Expected:** No change before vs after. Any drop indicates data loss; any spike indicates duplication.

### Exporter Queue Size

```
_collector=<cluster> namespace=<ns> metric=otelcol_exporter_queue_size statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 10m | avg by statefulset
```

**Expected:** Stable and well below queue capacity (configured `queue_size: 10000`). A growing queue indicates the exporter can't keep up.
After single-layer, expect a decrease due to eliminated inter-pod backpressure and connection reuse.

### Exporter Send Failures

```
_collector=<cluster> namespace=<ns> metric=otelcol_exporter_send_failed_metric_points statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | rate counter | sum
```

**Expected:** Zero or unchanged. Failures could indicate resource pressure or connectivity issues from the new pod topology.

### Receiver Refused Points (Backpressure)

```
_collector=<cluster> namespace=<ns> metric=otelcol_receiver_refused_metric_points statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | rate counter | sum
```

**Expected:** Zero. Non-zero values indicate the pipeline is applying backpressure due to resource constraints.

---

## 2. Resource Utilization

These metrics determine the net resource cost savings.

### CPU Usage

```
_collector=<cluster> namespace=<ns> metric=otelcol_process_cpu_seconds statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | rate counter | sum
```

**Expected:** Lower after enabling single-layer (typically 30-50% reduction due to eliminated serialization overhead and connection churn).

### Memory (RSS) — Total

```
_collector=<cluster> namespace=<ns> metric=otelcol_process_memory_rss statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | avg
```

**Expected:** The collector pods will use more memory individually (they now hold the k8sattributes cache), but the total across all pods
should be similar or lower since the metadata pods are eliminated.

### Memory vs Limits (per pod)

```
_collector=<cluster> namespace=<ns> metric=container_memory_working_set_bytes pod=(*-metrics-collector* OR *-otelcol-metrics*)
| quantize to 1m | max by pod
```

Compare against the configured memory limit. Ensure headroom remains (recommend <80% of limit). If approaching limits, increase collector
memory requests/limits.

### PVC Disk Usage

```
_collector=<cluster> namespace=<ns> metric=kubelet_volume_stats_used_bytes persistentvolumeclaim=file-storage-*-metrics-collector*
| quantize to 5m | max by persistentvolumeclaim
```

**Expected:** The collector PVCs now hold sending queue data that was previously on metadata PVCs. Monitor that usage stays well below the
provisioned size (e.g., 70Gi).

### Total Pod Count

Count the total number of pods before (collector + metadata replicas) vs after (collector only). Fewer pods = less scheduling overhead,
fewer PVCs, fewer node resources consumed.

---

## 3. Pipeline Latency

The sumologic exporter emits custom telemetry: `otelcol_exporter_requests_duration` (cumulative ms) and `otelcol_exporter_requests_sent`
(cumulative count). To compute average per-request latency, use a multi-query approach in Sumo Logic:

### Average Export Request Latency (ms)

**Query A** — total request duration rate:

```
_collector=<cluster> namespace=<ns> metric=otelcol_exporter_requests_duration statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | rate counter | sum by pipeline
```

**Query B** — total request count rate:

```
_collector=<cluster> namespace=<ns> metric=otelcol_exporter_requests_sent statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | rate counter | sum by pipeline
```

**Query C** — average latency per request:

```
#A / #B
```

**Expected:** Lower or unchanged after enabling single-layer pipeline. The two-layer setup used `disable_keep_alives: true` on the OTLP HTTP
exporter (new TCP connection per request), which added connection setup overhead. The single-layer sumologic exporter reuses connections and
sends larger payloads (up to 16MB per request), resulting in fewer round-trips and lower average latency.

### Average Payload Size per Request (bytes)

**Query D** — bytes sent rate:

```
_collector=<cluster> namespace=<ns> metric=otelcol_exporter_requests_bytes statefulset=(*-metrics-collector OR *-otelcol-metrics)
| quantize to 1m | rate counter | sum by pipeline
```

**Query E** — average payload size per request:

```
#D / #B
```

**Expected:** After single-layer, payload size per request should be significantly larger (up to 16MB max_request_body_size vs small OTLP
proto batches before), confirming fewer but fatter requests — which explains the lower queue depth.

### Backpressure Detection

```
_collector=<cluster> namespace=<ns> metric=otelcol_exporter_queue_size statefulset=*-metrics-collector
| quantize to 1m | max
```

**Expected:** Well below the configured `queue_size` of 10,000. If max approaches this limit, the pipeline is under backpressure and needs
more resources or replicas.

---

## 4. Kubernetes-Level Health

### Pod Restarts

```
_collector=<cluster> namespace=<ns> metric=kube_pod_container_status_restarts_total pod=(*-metrics-collector* OR *-otelcol-metrics*)
| quantize to 1h | rate counter | sum
```

**Expected:** Zero. OOMKills or crashloops after enabling single-layer indicate insufficient resource limits.

### OOMKill Events

```
_collector=<cluster> namespace=<ns> metric=kube_pod_container_status_last_terminated_reason pod=*-metrics-collector* reason=OOMKilled
```

**Expected:** None. If present, increase memory limits on the collector.

### HPA Behavior (if configured)

```
_collector=<cluster> namespace=<ns> metric=kube_horizontalpodautoscaler_status_current_replicas hpa=*metrics-collector*
| quantize to 5m | avg
```

**Expected:** Stable replica count. Frequent scaling events suggest resource thresholds need tuning.

---

## 5. Network

### Inter-Pod Traffic Reduction

Before single-layer, the collector sent all scraped data over the network to the metadata StatefulSet. After, this traffic is eliminated
(processing is in-process).

```
_collector=<cluster> namespace=<ns> metric=container_network_transmit_bytes_total pod=*-metrics-collector*
| quantize to 5m | rate counter | sum
```

**Expected:** Noticeable reduction in network transmit from collector pods (no longer forwarding to metadata).

---

## 6. Cost Summary Table

| Parameter                        | Before (Two-Layer) | After (Single-Layer) | Change |
| -------------------------------- | ------------------ | -------------------- | ------ |
| Total CPU (cores)                |                    |                      |        |
| Total Memory (GB)                |                    |                      |        |
| Pod Count                        |                    |                      |        |
| PVC Count                        |                    |                      |        |
| PVC Total Size (GB)              |                    |                      |        |
| Network (intra-namespace GB/day) |                    |                      |        |
| Metric Points/min                |                    |                      |        |
| Avg Queue Size                   |                    |                      |        |
| Avg Export Latency (ms)          |                    |                      |        |
| Avg Payload Size (bytes)         |                    |                      |        |
| Pod Restarts (24h)               |                    |                      |        |

---

## 7. Recommended Validation Timeline

1. **Hour 1-4:** Verify data correctness (points exported unchanged, zero send failures, zero refused points)
2. **Day 1:** Compare CPU and memory utilization, check for OOMKills/restarts
3. **Day 2-3:** Monitor PVC growth rate, queue sizes, HPA stability, export latency
4. **Day 7:** Full cost comparison, confirm steady-state behavior

Only promote to production after the full 7-day observation window shows stable behavior across all parameters.

## Proofs

Atttach the screenshots of the above metrics to this document.
