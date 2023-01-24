# List of metrics scraped by Prometheus

- [Metrics](#metrics)
- [Aggregations](#aggregations)
  - [`:kube_pod_info_node_count:`](#kube_pod_info_node_count)
  - [`:node_cpu_saturation_load1:`](#node_cpu_saturation_load1)
  - [`:node_cpu_utilisation:avg1m`](#node_cpu_utilisationavg1m)
  - [`:node_disk_saturation:avg_irate`](#node_disk_saturationavg_irate)
  - [`:node_disk_utilisation:avg_irate`](#node_disk_utilisationavg_irate)
  - [`:node_memory_swap_io_bytes:sum_rate`](#node_memory_swap_io_bytessum_rate)
  - [`:node_memory_utilisation:`](#node_memory_utilisation)
  - [`:node_net_saturation:sum_irate`](#node_net_saturationsum_irate)
  - [`:node_net_utilisation:sum_irate`](#node_net_utilisationsum_irate)
  - [`cluster_quantile:apiserver_request_duration_seconds:histogram_quantile`](#cluster_quantileapiserver_request_duration_secondshistogram_quantile)
  - [`cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile`](#cluster_quantilescheduler_binding_duration_secondshistogram_quantile)
  - [`cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile`](#cluster_quantilescheduler_e2e_scheduling_duration_secondshistogram_quantile)
  - [`cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile`](#cluster_quantilescheduler_scheduling_algorithm_duration_secondshistogram_quantile)
  - [`instance:node_filesystem_usage:sum`](#instancenode_filesystem_usagesum)
  - [`instance:node_network_receive_bytes:rate:sum`](#instancenode_network_receive_bytesratesum)
  - [`node:cluster_cpu_utilisation:ratio`](#nodecluster_cpu_utilisationratio)
  - [`node:cluster_memory_utilisation:ratio`](#nodecluster_memory_utilisationratio)
  - [`node:node_cpu_saturation_load1:`](#nodenode_cpu_saturation_load1)
  - [`node:node_cpu_utilisation:avg1m`](#nodenode_cpu_utilisationavg1m)
  - [`node:node_disk_saturation:avg_irate`](#nodenode_disk_saturationavg_irate)
  - [`node:node_disk_utilisation:avg_irate`](#nodenode_disk_utilisationavg_irate)
  - [`node:node_filesystem_avail:`](#nodenode_filesystem_avail)
  - [`node:node_filesystem_usage:`](#nodenode_filesystem_usage)
  - [`node:node_inodes_free:`](#nodenode_inodes_free)
  - [`node:node_inodes_total:`](#nodenode_inodes_total)
  - [`node:node_memory_bytes_total:sum`](#nodenode_memory_bytes_totalsum)
  - [`node:node_memory_swap_io_bytes:sum_rate`](#nodenode_memory_swap_io_bytessum_rate)
  - [`node:node_memory_utilisation:`](#nodenode_memory_utilisation)
  - [`node:node_memory_utilisation:ratio`](#nodenode_memory_utilisationratio)
  - [`node:node_memory_utilisation_2:`](#nodenode_memory_utilisation_2)
  - [`node:node_net_saturation:sum_irate`](#nodenode_net_saturationsum_irate)
  - [`node:node_net_utilisation:sum_irate`](#nodenode_net_utilisationsum_irate)
  - [`node:node_num_cpu:sum`](#nodenode_num_cpusum)
  - [`node_namespace_pod:kube_pod_info:`](#node_namespace_podkube_pod_info)
- [Aggregations not forwarded to Sumo](#aggregations-not-forwarded-to-sumo)
  - [`node:node_memory_bytes_available:sum`](#nodenode_memory_bytes_availablesum)

## Metrics

The following table contains information about metrics scraped by Sumo Logic's Prometheus:

- name - name of the metric
- source - originated source of the metric
- forwarded - `yes` if metric is being forwarded to Sumo Logic

| name                                                     | source             | forwarded |
| -------------------------------------------------------- | ------------------ | --------- |
| `apiserver_request_count`                                | apiserver          | yes       |
| `apiserver_request_total`                                | apiserver          | yes       |
| `apiserver_request_duration_seconds_count`               | apiserver          | yes       |
| `apiserver_request_duration_seconds_bucket`              | apiserver          | no        |
| `apiserver_request_duration_seconds_sum`                 | apiserver          | yes       |
| `apiserver_request_latencies_count`                      | apiserver          | yes       |
| `apiserver_request_latencies_sum`                        | apiserver          | yes       |
| `apiserver_request_latencies_summary`                    | apiserver          | yes       |
| `apiserver_request_latencies_summary_count`              | apiserver          | yes       |
| `apiserver_request_latencies_summary_sum`                | apiserver          | yes       |
| `kubelet_docker_operations_errors`                       | kubelet            | yes       |
| `kubelet_docker_operations_errors_total`                 | kubelet            | yes       |
| `kubelet_docker_operations_duration_seconds_count`       | kubelet            | yes       |
| `kubelet_docker_operations_duration_seconds_sum`         | kubelet            | yes       |
| `kubelet_runtime_operations_duration_seconds_count`      | kubelet            | yes       |
| `kubelet_runtime_operations_duration_seconds_sum`        | kubelet            | yes       |
| `kubelet_running_container_count`                        | kubelet            | yes       |
| `kubelet_running_containers`                             | kubelet            | yes       |
| `kubelet_running_pod_count`                              | kubelet            | yes       |
| `kubelet_running_pods`                                   | kubelet            | yes       |
| `kubelet_docker_operations_latency_microseconds`         | kubelet            | yes       |
| `kubelet_docker_operations_latency_microseconds_count`   | kubelet            | yes       |
| `kubelet_docker_operations_latency_microseconds_sum`     | kubelet            | yes       |
| `kubelet_runtime_operations_latency_microseconds`        | kubelet            | yes       |
| `kubelet_runtime_operations_latency_microseconds_count`  | kubelet            | yes       |
| `kubelet_runtime_operations_latency_microseconds_sum`    | kubelet            | yes       |
| `container_cpu_usage_seconds_total`                      | cadvisor           | yes       |
| `container_fs_limit_bytes`                               | cadvisor           | yes       |
| `container_fs_usage_bytes`                               | cadvisor           | yes       |
| `container_memory_working_set_bytes`                     | cadvisor           | yes       |
| `container_cpu_cfs_throttled_seconds_total`              | cadvisor           | yes       |
| `container_network_receive_bytes_total`                  | cadvisor           | yes       |
| `container_network_transmit_bytes_total`                 | cadvisor           | yes       |
| `cloudprovider_aws_api_request_duration_seconds_bucket`  | kube-controller    | yes       |
| `cloudprovider_aws_api_request_duration_seconds_count`   | kube-controller    | yes       |
| `cloudprovider_aws_api_request_duration_seconds_sum`     | kube-controller    | yes       |
| `coredns_cache_size`                                     | coredns            | yes       |
| `coredns_cache_entries`                                  | coredns            | yes       |
| `coredns_cache_hits_total`                               | coredns            | yes       |
| `coredns_cache_misses_total`                             | coredns            | yes       |
| `coredns_dns_request_duration_seconds_count`             | coredns            | yes       |
| `coredns_dns_request_duration_seconds_sum`               | coredns            | yes       |
| `coredns_dns_request_count_total`                        | coredns            | yes       |
| `coredns_dns_requests_total`                             | coredns            | yes       |
| `coredns_dns_response_rcode_count_total`                 | coredns            | yes       |
| `coredns_dns_responses_total`                            | coredns            | yes       |
| `coredns_forward_request_count_total`                    | coredns            | yes       |
| `coredns_forward_requests_total`                         | coredns            | yes       |
| `process_cpu_seconds_total`                              | coredns            | yes       |
| `process_open_fds`                                       | coredns            | yes       |
| `process_resident_memory_bytes`                          | coredns            | yes       |
| `etcd_request_cache_get_duration_seconds_count`          | kube-etcd          | yes       |
| `etcd_request_cache_get_duration_seconds_sum`            | kube-etcd          | yes       |
| `etcd_request_cache_add_duration_seconds_count`          | kube-etcd          | yes       |
| `etcd_request_cache_add_duration_seconds_sum`            | kube-etcd          | yes       |
| `etcd_request_cache_add_latencies_summary_count`         | kube-etcd          | yes       |
| `etcd_request_cache_add_latencies_summary_sum`           | kube-etcd          | yes       |
| `etcd_request_cache_get_latencies_summary_count`         | kube-etcd          | yes       |
| `etcd_request_cache_get_latencies_summary_sum`           | kube-etcd          | yes       |
| `etcd_helper_cache_hit_count`                            | kube-etcd          | yes       |
| `etcd_helper_cache_hit_total`                            | kube-etcd          | yes       |
| `etcd_helper_cache_miss_count`                           | kube-etcd          | yes       |
| `etcd_helper_cache_miss_total`                           | kube-etcd          | yes       |
| `etcd_debugging_mvcc_db_total_size_in_bytes`             | etcd-server        | yes       |
| `etcd_debugging_store_expires_total`                     | etcd-server        | yes       |
| `etcd_debugging_store_watchers`                          | etcd-server        | yes       |
| `etcd_disk_backend_commit_duration_seconds_bucket`       | etcd-server        | yes       |
| `etcd_disk_wal_fsync_duration_seconds_bucket`            | etcd-server        | yes       |
| `etcd_grpc_proxy_cache_hits_total`                       | etcd-server        | yes       |
| `etcd_grpc_proxy_cache_misses_total`                     | etcd-server        | yes       |
| `etcd_network_client_grpc_received_bytes_total`          | etcd-server        | yes       |
| `etcd_network_client_grpc_sent_bytes_total`              | etcd-server        | yes       |
| `etcd_server_has_leader`                                 | etcd-server        | yes       |
| `etcd_server_leader_changes_seen_total`                  | etcd-server        | yes       |
| `etcd_server_proposals_applied_total`                    | etcd-server        | yes       |
| `etcd_server_proposals_committed_total`                  | etcd-server        | yes       |
| `etcd_server_proposals_failed_total`                     | etcd-server        | yes       |
| `etcd_server_proposals_pending`                          | etcd-server        | yes       |
| `process_cpu_seconds_total`                              | etcd-server        | yes       |
| `process_open_fds`                                       | etcd-server        | yes       |
| `process_resident_memory_bytes`                          | etcd-server        | yes       |
| `scheduler` metrics_latency_microseconds                 | kube-scheduler     | yes       |
| `scheduler_e2e_scheduling_duration_seconds_bucket`       | kube-scheduler     | yes       |
| `scheduler_e2e_scheduling_duration_seconds_count`        | kube-scheduler     | yes       |
| `scheduler_e2e_scheduling_duration_seconds_sum`          | kube-scheduler     | yes       |
| `scheduler_binding_duration_seconds_bucket`              | kube-scheduler     | no        |
| `scheduler_binding_duration_seconds_count`               | kube-scheduler     | yes       |
| `scheduler_binding_duration_seconds_sum`                 | kube-scheduler     | yes       |
| `scheduler_scheduling_algorithm_duration_seconds_bucket` | kube-scheduler     | no        |
| `scheduler_scheduling_algorithm_duration_seconds_count`  | kube-scheduler     | yes       |
| `scheduler_scheduling_algorithm_duration_seconds_sum`    | kube-scheduler     | yes       |
| `kube_daemonset_status_current_number_scheduled`         | kube-state-metrics | yes       |
| `kube_daemonset_status_desired_number_scheduled`         | kube-state-metrics | yes       |
| `kube_daemonset_status_number_misscheduled`              | kube-state-metrics | yes       |
| `kube_daemonset_status_number_unavailable`               | kube-state-metrics | yes       |
| `kube_deployment_spec_replicas`                          | kube-state-metrics | yes       |
| `kube_deployment_status_replicas_available`              | kube-state-metrics | yes       |
| `kube_deployment_status_replicas_unavailable`            | kube-state-metrics | yes       |
| `kube_node_info`                                         | kube-state-metrics | yes       |
| `kube_node_status_allocatable`                           | kube-state-metrics | yes       |
| `kube_node_status_capacity`                              | kube-state-metrics | yes       |
| `kube_node_status_condition`                             | kube-state-metrics | yes       |
| `kube_statefulset_metadata_generation`                   | kube-state-metrics | yes       |
| `kube_statefulset_replicas`                              | kube-state-metrics | yes       |
| `kube_statefulset_status_observed_generation`            | kube-state-metrics | yes       |
| `kube_statefulset_status_replicas`                       | kube-state-metrics | yes       |
| `kube_hpa_spec_max_replicas`                             | kube-state-metrics | yes       |
| `kube_hpa_spec_min_replicas`                             | kube-state-metrics | yes       |
| `kube_hpa_status_condition`                              | kube-state-metrics | yes       |
| `kube_hpa_status_current_replicas`                       | kube-state-metrics | yes       |
| `kube_hpa_status_desired_replicas`                       | kube-state-metrics | yes       |
| `kube` pod state metrics                                 | kube-state-metrics | yes       |
| `kube_pod_container_info`                                | kube-state-metrics | yes       |
| `kube_pod_container_resource_limits`                     | kube-state-metrics | yes       |
| `kube_pod_container_resource_requests`                   | kube-state-metrics | yes       |
| `kube_pod_container_status_ready`                        | kube-state-metrics | yes       |
| `kube_pod_container_status_restarts_total`               | kube-state-metrics | yes       |
| `kube_pod_container_status_terminated_reason`            | kube-state-metrics | yes       |
| `kube_pod_container_status_waiting_reason`               | kube-state-metrics | yes       |
| `kube_pod_status_phase`                                  | kube-state-metrics | yes       |
| `kube_pod_info`                                          | kube-state-metrics | no        |
| `kube_service_info`                                      | kube-state-metrics | yes       |
| `kube_service_spec_external_ip`                          | kube-state-metrics | yes       |
| `kube_service_spec_type`                                 | kube-state-metrics | yes       |
| `kube_service_status_load_balancer_ingress`              | kube-state-metrics | yes       |
| `node_cpu_seconds_total`                                 | node-exporter      | yes       |
| `node_load1`                                             | node-exporter      | yes       |
| `node_load5`                                             | node-exporter      | yes       |
| `node_load15`                                            | node-exporter      | yes       |
| `node_disk_io_time_weighted_seconds_total`               | node-exporter      | no        |
| `node_disk_io_time_seconds_total`                        | node-exporter      | no        |
| `node_vmstat_pgpgin`                                     | node-exporter      | no        |
| `node_vmstat_pgpgout`                                    | node-exporter      | no        |
| `node_memory_MemFree_bytes`                              | node-exporter      | no        |
| `node_memory_Cached_bytes`                               | node-exporter      | no        |
| `node_memory_Buffers_bytes`                              | node-exporter      | no        |
| `node_memory_MemTotal_bytes`                             | node-exporter      | no        |
| `node_network_receive_drop_total`                        | node-exporter      | no        |
| `node_network_transmit_drop_total`                       | node-exporter      | no        |
| `node_network_receive_bytes_total`                       | node-exporter      | no        |
| `node_network_transmit_bytes_total`                      | node-exporter      | no        |
| `node_filesystem_avail_bytes`                            | node-exporter      | no        |
| `node_filesystem_size_bytes`                             | node-exporter      | no        |
| `node_filesystem_files_free`                             | node-exporter      | no        |
| `node_filesystem_files`                                  | node-exporter      | no        |

## Aggregations

### `:kube_pod_info_node_count:`

Rule definition:

```text
sum(min(kube_pod_info) by (node))
```

Dependends on the following metrics and aggregations:

| name          | source             |
| ------------- | ------------------ |
| kube_pod_info | kube-state-metrics |

### `:node_cpu_saturation_load1:`

Rule definition:

```text
sum(node_load1{job="node-exporter"})
/
sum(node:node_num_cpu:sum)
```

Dependends on the following metrics and aggregations:

| name                                          | source        |
| --------------------------------------------- | ------------- |
| node_load1                                    | node-exporter |
| [node:node_num_cpu:sum](#nodenode_num_cpusum) | aggregations  |

### `:node_cpu_utilisation:avg1m`

Rule definition:

```text
1 - avg(rate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[1m]))
```

Dependends on the following metrics and aggregations:

| name                   | source        |
| ---------------------- | ------------- |
| node_cpu_seconds_total | node-exporter |

### `:node_disk_saturation:avg_irate`

Rule definition:

```text
avg(irate(node_disk_io_time_weighted_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m]))
```

Dependends on the following metrics and aggregations:

| name                                     | source        |
| ---------------------------------------- | ------------- |
| node_disk_io_time_weighted_seconds_total | node-exporter |

### `:node_disk_utilisation:avg_irate`

Rule definition:

```text
avg(irate(node_disk_io_time_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m]))
```

Dependends on the following metrics and aggregations:

| name                            | source        |
| ------------------------------- | ------------- |
| node_disk_io_time_seconds_total | node-exporter |

### `:node_memory_swap_io_bytes:sum_rate`

Rule definition:

```text
1e3 * sum(
  (rate(node_vmstat_pgpgin{job="node-exporter"}[1m])
+ rate(node_vmstat_pgpgout{job="node-exporter"}[1m]))
)
```

Dependends on the following metrics and aggregations:

| name                | source        |
| ------------------- | ------------- |
| node_vmstat_pgpgin  | node-exporter |
| node_vmstat_pgpgout | node-exporter |

### `:node_memory_utilisation:`

Rule definition:

```text
1 -
sum(
  node_memory_MemFree_bytes{job="node-exporter"} +
  node_memory_Cached_bytes{job="node-exporter"} +
  node_memory_Buffers_bytes{job="node-exporter"}
)
/
sum(node_memory_MemTotal_bytes{job="node-exporter"})
```

Dependends on the following metrics and aggregations:

| name                       | source        |
| -------------------------- | ------------- |
| node_memory_MemFree_bytes  | node-exporter |
| node_memory_Cached_bytes   | node-exporter |
| node_memory_Buffers_bytes  | node-exporter |
| node_memory_MemTotal_bytes | node-exporter |

### `:node_net_saturation:sum_irate`

Rule definition:

```text
sum(irate(node_network_receive_drop_total{job="node-exporter",device!~"veth.+"}[1m])) +
sum(irate(node_network_transmit_drop_total{job="node-exporter",device!~"veth.+"}[1m]))
```

Dependends on the following metrics and aggregations:

| name                             | source        |
| -------------------------------- | ------------- |
| node_network_receive_drop_total  | node-exporter |
| node_network_transmit_drop_total | node-exporter |

### `:node_net_utilisation:sum_irate`

Rule definition:

```text
sum(irate(node_network_receive_bytes_total{job="node-exporter",device!~"veth.+"}[1m])) +
sum(irate(node_network_transmit_bytes_total{job="node-exporter",device!~"veth.+"}[1m]))
```

Dependends on the following metrics and aggregations:

| name                              | source        |
| --------------------------------- | ------------- |
| node_network_receive_bytes_total  | node-exporter |
| node_network_transmit_bytes_total | node-exporter |

### `cluster_quantile:apiserver_request_duration_seconds:histogram_quantile`

NOTE: **DUPLICATED**

Rule definition:

```text
histogram_quantile(0.99, sum by (cluster, le, resource) (rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET"}[5m]))) > 0
histogram_quantile(0.99, sum by (cluster, le, resource) (rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"POST|PUT|PATCH|DELETE"}[5m]))) > 0
histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",subresource!="log",verb!~"LIST|WATCH|WATCHLIST|DELETECOLLECTION|PROXY|CONNECT"}[5m])) without(instance, pod))
histogram_quantile(0.9, sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",subresource!="log",verb!~"LIST|WATCH|WATCHLIST|DELETECOLLECTION|PROXY|CONNECT"}[5m])) without(instance, pod))
histogram_quantile(0.5, sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",subresource!="log",verb!~"LIST|WATCH|WATCHLIST|DELETECOLLECTION|PROXY|CONNECT"}[5m])) without(instance, pod))
```

Dependends on the following metrics and aggregations:

| name                                      | source    |
| ----------------------------------------- | --------- |
| apiserver_request_duration_seconds_bucket | apiserver |

### `cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile`

Rule definition:

```text
histogram_quantile(0.99, sum(rate(scheduler_binding_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
histogram_quantile(0.9, sum(rate(scheduler_binding_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
histogram_quantile(0.5, sum(rate(scheduler_binding_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
```

Dependends on the following metrics and aggregations:

| name                                      | source         |
| ----------------------------------------- | -------------- |
| scheduler_binding_duration_seconds_bucket | kube-scheduler |

### `cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile`

Rule definition:

```text
histogram_quantile(0.99, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
histogram_quantile(0.9, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
histogram_quantile(0.5, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
```

Dependends on the following metrics and aggregations:

| name                                             | source         |
| ------------------------------------------------ | -------------- |
| scheduler_e2e_scheduling_duration_seconds_bucket | kube-scheduler |

### `cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile`

Rule definition:

```text
histogram_quantile(0.99, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
histogram_quantile(0.9, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
histogram_quantile(0.5, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
```

Dependends on the following metrics and aggregations:

| name                                                   | source         |
| ------------------------------------------------------ | -------------- |
| scheduler_scheduling_algorithm_duration_seconds_bucket | kube-scheduler |

### `instance:node_filesystem_usage:sum`

No rules definition available

### `instance:node_network_receive_bytes:rate:sum`

Rule definition:

```text
sum(rate(node_network_receive_bytes_total[3m])) BY (instance)
```

Dependends on the following metrics and aggregations:

| name                             | source        |
| -------------------------------- | ------------- |
| node_network_receive_bytes_total | node-exporter |

### `node:cluster_cpu_utilisation:ratio`

Rule definition:

```text
node:node_cpu_utilisation:avg1m
  *
node:node_num_cpu:sum
  /
scalar(sum(node:node_num_cpu:sum))
```

Dependends on the following metrics and aggregations:

| name                                                              | source      |
| ----------------------------------------------------------------- | ----------- |
| [node:node_cpu_utilisation:avg1m](#nodenode_cpu_utilisationavg1m) | aggregation |
| [node:node_num_cpu:sum](#nodenode_num_cpusum)                     | aggregation |

### `node:cluster_memory_utilisation:ratio`

Rule definition:

```text
(node:node_memory_bytes_total:sum - node:node_memory_bytes_available:sum)
/
scalar(sum(node:node_memory_bytes_total:sum))
```

Dependends on the following metrics and aggregations:

| name                                                                        | source      |
| --------------------------------------------------------------------------- | ----------- |
| [node:node_memory_bytes_total:sum](#nodenode_memory_bytes_totalsum)         | aggregation |
| [node:node_memory_bytes_available:sum](#nodenode_memory_bytes_availablesum) | aggregation |

### `node:node_cpu_saturation_load1:`

Rule definition:

```text
sum by (node) (
  node_load1{job="node-exporter"}
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
/
node:node_num_cpu:sum
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_load1                                                            | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |
| [node:node_num_cpu:sum](#nodenode_num_cpusum)                         | aggregation   |

### `node:node_cpu_utilisation:avg1m`

Rule definition:

```text
1 - avg by (node) (
  rate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[1m])
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_cpu_seconds_total                                                | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_disk_saturation:avg_irate`

Rule definition:

```text
avg by (node) (
  irate(node_disk_io_time_weighted_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m])
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_disk_io_time_weighted_seconds_total                              | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_disk_utilisation:avg_irate`

Rule definition:

```text
avg by (node) (
  irate(node_disk_io_time_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m])
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_disk_io_time_seconds_total                                       | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_filesystem_avail:`

Rule definition:

```text
max by (instance, namespace, pod, device) (
  node_filesystem_avail_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
  /
  node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
  )
```

Dependends on the following metrics and aggregations:

| name                        | source        |
| --------------------------- | ------------- |
| node_filesystem_avail_bytes | node-exporter |
| node_filesystem_size_bytes  | node-exporter |

### `node:node_filesystem_usage:`

Rule definition:

```text
max by (instance, namespace, pod, device) ((node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
- node_filesystem_avail_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
/ node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
```

Dependends on the following metrics and aggregations:

| name                        | source        |
| --------------------------- | ------------- |
| node_filesystem_avail_bytes | node-exporter |
| node_filesystem_size_bytes  | node-exporter |

### `node:node_inodes_free:`

Rule definition:

```text
max(
  max(
    kube_pod_info{job="kube-state-metrics", host_ip!=""}
  ) by (node, host_ip)
  * on (host_ip) group_right (node)
  label_replace(
    (
      max(node_filesystem_files_free{job="node-exporter", mountpoint="/"})
      by (instance)
    ), "host_ip", "$1", "instance", "(.*):.*"
  )
) by (node)
```

Dependends on the following metrics and aggregations:

| name                       | source             |
| -------------------------- | ------------------ |
| kube_pod_info              | kube-state-metrics |
| node_filesystem_files_free | node-exporter      |

### `node:node_inodes_total:`

Rule definition:

```text
max(
  max(
    kube_pod_info{job="kube-state-metrics", host_ip!=""}
  ) by (node, host_ip)
  * on (host_ip) group_right (node)
  label_replace(
    (
      max(node_filesystem_files{job="node-exporter", mountpoint="/"})
      by (instance)
    ), "host_ip", "$1", "instance", "(.*):.*"
  )
) by (node)
```

Dependends on the following metrics and aggregations:

| name                  | source             |
| --------------------- | ------------------ |
| kube_pod_info         | kube-state-metrics |
| node_filesystem_files | node-exporter      |

### `node:node_memory_bytes_total:sum`

Rule definition:

```text
sum by (node) (
  node_memory_MemTotal_bytes{job="node-exporter"}
  * on (namespace, pod) group_left(node)
    node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_memory_MemTotal_bytes                                            | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_memory_swap_io_bytes:sum_rate`

Rule definition:

```text
1e3 * sum by (node) (
  (rate(node_vmstat_pgpgin{job="node-exporter"}[1m])
+ rate(node_vmstat_pgpgout{job="node-exporter"}[1m]))
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_vmstat_pgpgin                                                    | node-exporter |
| node_vmstat_pgpgout                                                   | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_memory_utilisation:`

Rule definition:

```text
1 -
sum by (node) (
  (
    node_memory_MemFree_bytes{job="node-exporter"} +
    node_memory_Cached_bytes{job="node-exporter"} +
    node_memory_Buffers_bytes{job="node-exporter"}
  )
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
/
sum by (node) (
  node_memory_MemTotal_bytes{job="node-exporter"}
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_memory_MemFree_bytes                                             | node-exporter |
| node_memory_Cached_bytes                                              | node-exporter |
| node_memory_Buffers_bytes                                             | node-exporter |
| node_memory_MemTotal_bytes                                            | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_memory_utilisation:ratio`

Rule definition:

```text
(node:node_memory_bytes_total:sum - node:node_memory_bytes_available:sum)
/
node:node_memory_bytes_total:sum
```

Dependends on the following metrics and aggregations:

| name                                                                        | source      |
| --------------------------------------------------------------------------- | ----------- |
| [node:node_memory_bytes_available:sum](#nodenode_memory_bytes_availablesum) | aggregation |
| [node:node_memory_bytes_total:sum](#nodenode_memory_bytes_totalsum)         | aggregation |

### `node:node_memory_utilisation_2:`

Rule definition:

```text
1 - (node:node_memory_bytes_available:sum / node:node_memory_bytes_total:sum)
```

Dependends on the following metrics and aggregations:

| name                                                                        | source      |
| --------------------------------------------------------------------------- | ----------- |
| [node:node_memory_bytes_available:sum](#nodenode_memory_bytes_availablesum) | aggregation |
| [node:node_memory_bytes_total:sum](#nodenode_memory_bytes_totalsum)         | aggregation |

### `node:node_net_saturation:sum_irate`

Rule definition:

```text
sum by (node) (
  (irate(node_network_receive_drop_total{job="node-exporter",device!~"veth.+"}[1m]) +
  irate(node_network_transmit_drop_total{job="node-exporter",device!~"veth.+"}[1m]))
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_network_receive_drop_total                                       | node-exporter |
| node_network_transmit_drop_total                                      | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_net_utilisation:sum_irate`

Rule definition:

```text
sum by (node) (
  (irate(node_network_receive_bytes_total{job="node-exporter",device!~"veth.+"}[1m]) +
  irate(node_network_transmit_bytes_total{job="node-exporter",device!~"veth.+"}[1m]))
* on (namespace, pod) group_left(node)
  node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_network_receive_bytes_total                                      | node-exporter |
| node_network_transmit_bytes_total                                     | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node:node_num_cpu:sum`

Rule definition:

```text
count by (cluster, node) (sum by (node, cpu) (
  node_cpu_seconds_total{job="node-exporter"}
* on (namespace, pod) group_left(node)
  topk by(namespace, pod) (1, node_namespace_pod:kube_pod_info:)
))
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_cpu_seconds_total                                                | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |

### `node_namespace_pod:kube_pod_info:`

Rule definition:

```text
topk by(namespace, pod) (1,
  max by (node, namespace, pod) (
    label_replace(kube_pod_info{job="kube-state-metrics",node!=""}, "pod", "$1", "pod", "(.*)")
))
```

Dependends on the following metrics and aggregations:

| name          | source             |
| ------------- | ------------------ |
| kube_pod_info | kube-state-metrics |

## Aggregations not forwarded to Sumo

### `node:node_memory_bytes_available:sum`

Rule definition:

```text
sum by (node) (
  (
    node_memory_MemFree_bytes{job="node-exporter"} +
    node_memory_Cached_bytes{job="node-exporter"} +
    node_memory_Buffers_bytes{job="node-exporter"}
  )
  * on (namespace, pod) group_left(node)
    node_namespace_pod:kube_pod_info:
)
```

Dependends on the following metrics and aggregations:

| name                                                                  | source        |
| --------------------------------------------------------------------- | ------------- |
| node_memory_MemFree_bytes                                             | node-exporter |
| node_memory_Cached_bytes                                              | node-exporter |
| node_memory_Buffers_bytes                                             | node-exporter |
| [node_namespace_pod:kube_pod_info:](#node_namespace_podkube_pod_info) | aggregation   |
