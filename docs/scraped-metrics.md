# List of metrics scraped by Prometheus

- [List of metrics scraped by Prometheus](#list-of-metrics-scraped-by-prometheus)
  - [Metrics](#metrics)
  - [Aggregations (removed)](#aggregations-removed)
    - [`:kube_pod_info_node_count:`](#kube_pod_info_node_count)
    - [`:node_cpu_saturation_load1:`](#node_cpu_saturation_load1)
    - [`:node_cpu_utilisation:avg1m`](#node_cpu_utilisationavg1m)
    - [`:node_disk_saturation:avg_irate`](#node_disk_saturationavg_irate)
    - [`:node_disk_utilisation:avg_irate`](#node_disk_utilisationavg_irate)
    - [`:node_memory_swap_io_bytes:sum_rate`](#node_memory_swap_io_bytessum_rate)
    - [`:node_memory_utilisation:`](#node_memory_utilisation)
    - [`:node_net_saturation:sum_irate`](#node_net_saturationsum_irate)
    - [`:node_net_utilisation:sum_irate`](#node_net_utilisationsum_irate)
    - [`cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile`](#cluster_quantilescheduler_scheduling_algorithm_duration_secondshistogram_quantile)
    - [`instance:node_network_receive_bytes:rate:sum`](#instancenode_network_receive_bytesratesum)
    - [`node:cluster_cpu_utilisation:ratio`](#nodecluster_cpu_utilisationratio)
    - [`node:cluster_memory_utilisation:ratio`](#nodecluster_memory_utilisationratio)
    - [`node:node_cpu_saturation_load1:`](#nodenode_cpu_saturation_load1)
    - [`node:node_cpu_utilisation:avg1m`](#nodenode_cpu_utilisationavg1m)
    - [`node:node_disk_saturation:avg_irate`](#nodenode_disk_saturationavg_irate)
    - [`node:node_disk_utilisation:avg_irate`](#nodenode_disk_utilisationavg_irate)
    - [`node:node_filesystem_avail:`](#nodenode_filesystem_avail)
    - [`node:node_filesystem_usage:`](#nodenode_filesystem_usage)
    - [`node:node_memory_bytes_total:sum`](#nodenode_memory_bytes_totalsum)
    - [`node:node_memory_swap_io_bytes:sum_rate`](#nodenode_memory_swap_io_bytessum_rate)
    - [`node:node_memory_utilisation:`](#nodenode_memory_utilisation)
    - [`node:node_memory_utilisation:ratio`](#nodenode_memory_utilisationratio)
    - [`node:node_net_saturation:sum_irate`](#nodenode_net_saturationsum_irate)
    - [`node:node_net_utilisation:sum_irate`](#nodenode_net_utilisationsum_irate)
    - [`node:node_num_cpu:sum`](#nodenode_num_cpusum)

## Metrics

The following table contains information about metrics scraped by Sumo Logic's metrics collector:

- name - name of the metric
- source - originated source of the metric

| name                                              | source             |
| ------------------------------------------------- | ------------------ |
| `apiserver_request_count`                         | apiserver          |
| `apiserver_request_total`                         | apiserver          |
| `kubelet_docker_operations_errors`                | kubelet            |
| `kubelet_docker_operations_errors_total`          | kubelet            |
| `kubelet_running_container_count`                 | kubelet            |
| `kubelet_running_containers`                      | kubelet            |
| `kubelet_running_pod_count`                       | kubelet            |
| `kubelet_running_pods`                            | kubelet            |
| `kubelet_docker_operations_latency_microseconds`  | kubelet            |
| `kubelet_runtime_operations_latency_microseconds` | kubelet            |
| `container_cpu_usage_seconds_total`               | cadvisor           |
| `container_fs_limit_bytes`                        | cadvisor           |
| `container_fs_usage_bytes`                        | cadvisor           |
| `container_memory_working_set_bytes`              | cadvisor           |
| `container_cpu_cfs_throttled_seconds_total`       | cadvisor           |
| `container_network_receive_bytes_total`           | cadvisor           |
| `container_network_transmit_bytes_total`          | cadvisor           |
| `coredns_cache_size`                              | coredns            |
| `coredns_cache_entries`                           | coredns            |
| `coredns_cache_hits_total`                        | coredns            |
| `coredns_cache_misses_total`                      | coredns            |
| `coredns_dns_request_count_total`                 | coredns            |
| `coredns_dns_requests_total`                      | coredns            |
| `coredns_dns_response_rcode_count_total`          | coredns            |
| `coredns_dns_responses_total`                     | coredns            |
| `coredns_forward_request_count_total`             | coredns            |
| `coredns_forward_requests_total`                  | coredns            |
| `process_cpu_seconds_total`                       | coredns            |
| `process_open_fds`                                | coredns            |
| `process_resident_memory_bytes`                   | coredns            |
| `etcd_helper_cache_hit_count`                     | kube-etcd          |
| `etcd_helper_cache_hit_total`                     | kube-etcd          |
| `etcd_helper_cache_miss_count`                    | kube-etcd          |
| `etcd_helper_cache_miss_total`                    | kube-etcd          |
| `etcd_debugging_mvcc_db_total_size_in_bytes`      | etcd-server        |
| `etcd_debugging_store_expires_total`              | etcd-server        |
| `etcd_debugging_store_watchers`                   | etcd-server        |
| `etcd_grpc_proxy_cache_hits_total`                | etcd-server        |
| `etcd_grpc_proxy_cache_misses_total`              | etcd-server        |
| `etcd_network_client_grpc_received_bytes_total`   | etcd-server        |
| `etcd_network_client_grpc_sent_bytes_total`       | etcd-server        |
| `etcd_server_has_leader`                          | etcd-server        |
| `etcd_server_leader_changes_seen_total`           | etcd-server        |
| `etcd_server_proposals_applied_total`             | etcd-server        |
| `etcd_server_proposals_committed_total`           | etcd-server        |
| `etcd_server_proposals_failed_total`              | etcd-server        |
| `etcd_server_proposals_pending`                   | etcd-server        |
| `process_cpu_seconds_total`                       | etcd-server        |
| `process_open_fds`                                | etcd-server        |
| `process_resident_memory_bytes`                   | etcd-server        |
| `scheduler` metrics_latency_microseconds          | kube-scheduler     |
| `kube_daemonset_status_current_number_scheduled`  | kube-state-metrics |
| `kube_daemonset_status_desired_number_scheduled`  | kube-state-metrics |
| `kube_daemonset_status_number_misscheduled`       | kube-state-metrics |
| `kube_daemonset_status_number_unavailable`        | kube-state-metrics |
| `kube_deployment_spec_replicas`                   | kube-state-metrics |
| `kube_deployment_status_replicas_available`       | kube-state-metrics |
| `kube_deployment_status_replicas_unavailable`     | kube-state-metrics |
| `kube_node_info`                                  | kube-state-metrics |
| `kube_node_status_allocatable`                    | kube-state-metrics |
| `kube_node_status_capacity`                       | kube-state-metrics |
| `kube_node_status_condition`                      | kube-state-metrics |
| `kube_statefulset_metadata_generation`            | kube-state-metrics |
| `kube_statefulset_replicas`                       | kube-state-metrics |
| `kube_statefulset_status_observed_generation`     | kube-state-metrics |
| `kube_statefulset_status_replicas`                | kube-state-metrics |
| `kube_hpa_spec_max_replicas`                      | kube-state-metrics |
| `kube_hpa_spec_min_replicas`                      | kube-state-metrics |
| `kube_hpa_status_condition`                       | kube-state-metrics |
| `kube_hpa_status_current_replicas`                | kube-state-metrics |
| `kube_hpa_status_desired_replicas`                | kube-state-metrics |
| `kube` pod state metrics                          | kube-state-metrics |
| `kube_pod_container_info`                         | kube-state-metrics |
| `kube_pod_container_resource_limits`              | kube-state-metrics |
| `kube_pod_container_resource_requests`            | kube-state-metrics |
| `kube_pod_container_status_ready`                 | kube-state-metrics |
| `kube_pod_container_status_restarts_total`        | kube-state-metrics |
| `kube_pod_container_status_terminated_reason`     | kube-state-metrics |
| `kube_pod_container_status_waiting_reason`        | kube-state-metrics |
| `kube_pod_status_phase`                           | kube-state-metrics |
| `kube_pod_info`                                   | kube-state-metrics |
| `kube_service_info`                               | kube-state-metrics |
| `kube_service_spec_external_ip`                   | kube-state-metrics |
| `kube_service_spec_type`                          | kube-state-metrics |
| `kube_service_status_load_balancer_ingress`       | kube-state-metrics |
| `node_cpu_seconds_total`                          | node-exporter      |
| `node_load1`                                      | node-exporter      |
| `node_load5`                                      | node-exporter      |
| `node_load15`                                     | node-exporter      |
| `node_disk_io_time_weighted_seconds_total`        | node-exporter      |
| `node_disk_io_time_seconds_total`                 | node-exporter      |
| `node_vmstat_pgpgin`                              | node-exporter      |
| `node_vmstat_pgpgout`                             | node-exporter      |
| `node_memory_MemFree_bytes`                       | node-exporter      |
| `node_memory_MemAvailable_bytes`                  | node-exporter      |
| `node_memory_Cached_bytes`                        | node-exporter      |
| `node_memory_Buffers_bytes`                       | node-exporter      |
| `node_memory_MemTotal_bytes`                      | node-exporter      |
| `node_network_receive_drop_total`                 | node-exporter      |
| `node_network_transmit_drop_total`                | node-exporter      |
| `node_network_receive_bytes_total`                | node-exporter      |
| `node_network_transmit_bytes_total`               | node-exporter      |
| `node_filesystem_avail_bytes`                     | node-exporter      |
| `node_filesystem_size_bytes`                      | node-exporter      |
| `node_filesystem_files_free`                      | node-exporter      |
| `node_filesystem_files`                           | node-exporter      |

## Aggregations (removed)

> **WARN** These aggregated metrics were generated by Prometheus. In version 4 of the Chart, Otel is the default metrics collector and it
> isn't capable of aggregating metrics in this manner. As such, this section now provides instructions on how to produce equivalent time
> series using Sumo queries.

### `:kube_pod_info_node_count:`

Sumo query:

```text
metric=kube_pod_info | sum by node
```

Depends on the following metrics:

| name          | source             |
| ------------- | ------------------ |
| kube_pod_info | kube-state-metrics |

### `:node_cpu_saturation_load1:`

Sumo query:

```text
#A: metric=node_load1
#B: metric=node_cpu_seconds_total mode=idle | count by node
#C: #A / #B
```

Depends on the following metrics:

| name                   | source        |
| ---------------------- | ------------- |
| node_load1             | node-exporter |
| node_cpu_seconds_total | node-exporter |

### `:node_cpu_utilisation:avg1m`

Sumo query:

```text
metric=node_cpu_seconds_total mode=idle | quantize 1m | rate | avg | eval 1 - _value
```

Depends on the following metrics:

| name                   | source        |
| ---------------------- | ------------- |
| node_cpu_seconds_total | node-exporter |

### `:node_disk_saturation:avg_irate`

Sumo query:

```text
metric=node_disk_io_time_weighted_seconds_total (device="nvme" OR device=rbd* OR device=sd* OR device=vd* OR device=xvd* OR device=dm-*) | quantize 1m | rate increasing | avg
```

Depends on the following metrics:

| name                                     | source        |
| ---------------------------------------- | ------------- |
| node_disk_io_time_weighted_seconds_total | node-exporter |

### `:node_disk_utilisation:avg_irate`

Sumo query:

```text
metric=node_disk_io_time_seconds_total | rate increasing | avg by node
```

Depends on the following metrics:

| name                            | source        |
| ------------------------------- | ------------- |
| node_disk_io_time_seconds_total | node-exporter |

### `:node_memory_swap_io_bytes:sum_rate`

Sumo query:

```text
#A: metric=node_vmstat_pgpgin | rate increasing | quantize 1m
#B: metric=node_vmstat_pgpgout | rate increasing | quantize 1m
#C: 1000 * (#A + #B)
```

Depends on the following metrics:

| name                | source        |
| ------------------- | ------------- |
| node_vmstat_pgpgin  | node-exporter |
| node_vmstat_pgpgout | node-exporter |

### `:node_memory_utilisation:`

Sumo query:

```text
#A: metric=node_memory_MemAvailable_bytes
#B: metric=node_memory_MemTotal_bytes
#C: 1 - #A / #B

```

Depends on the following metrics:

| name                           | source        |
| ------------------------------ | ------------- |
| node_memory_MemAvailable_bytes | node-exporter |
| node_memory_MemTotal_bytes     | node-exporter |

### `:node_net_saturation:sum_irate`

Sumo query:

```text
#A: metric=node_network_receive_drop_total !device="veth*" | rate increasing | sum
#B: metric=node_network_transmit_drop_total !device="veth*" | rate increasing | sum
#C: #A + #B
```

Depends on the following metrics:

| name                             | source        |
| -------------------------------- | ------------- |
| node_network_receive_drop_total  | node-exporter |
| node_network_transmit_drop_total | node-exporter |

### `:node_net_utilisation:sum_irate`

Sumo query:

```text
#A: metric=node_network_receive_bytes_total !device=veth* | rate increasing | sum by node
#B: metric=node_network_transmit_bytes_total !device=veth* | rate increasing | sum by node
#C: #A + #B along node

```

Depends on the following metrics:

| name                              | source        |
| --------------------------------- | ------------- |
| node_network_receive_bytes_total  | node-exporter |
| node_network_transmit_bytes_total | node-exporter |

### `cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile`

Sumo query:

```text
cluster=kubernetes metric=scheduler_scheduling_algorithm_duration_seconds_bucket | rate increasing over 5m | sum | histogram_quantile .99
cluster=kubernetes metric=scheduler_scheduling_algorithm_duration_seconds_bucket | rate increasing over 5m | sum | histogram_quantile .9
cluster=kubernetes metric=scheduler_scheduling_algorithm_duration_seconds_bucket | rate increasing over 5m | sum | histogram_quantile .5
```

Depends on the following metrics:

| name                                                   | source         |
| ------------------------------------------------------ | -------------- |
| scheduler_scheduling_algorithm_duration_seconds_bucket | kube-scheduler |

### `instance:node_network_receive_bytes:rate:sum`

Sumo query:

```text
metric=node_network_receive_bytes_total | quantize 3m | rate increasing | sum by instance
```

Depends on the following metrics:

| name                             | source        |
| -------------------------------- | ------------- |
| node_network_receive_bytes_total | node-exporter |

### `node:cluster_cpu_utilisation:ratio`

Sumo query:

```text
metric=node_cpu_seconds_total !mode=idle | rate increasing | avg by node | avg
```

Depends on the following metrics:

| name                   | source        |
| ---------------------- | ------------- |
| node_cpu_seconds_total | node-exporter |

### `node:cluster_memory_utilisation:ratio`

Sumo query:

```text
#A: metric=node_memory_MemAvailable_bytes | sum
#B: metric=node_memory_MemTotal_bytes | sum
#C: 1 - #A / #B
```

Depends on the following metrics:

| name                           | source        |
| ------------------------------ | ------------- |
| node_memory_MemAvailable_bytes | node-exporter |
| node_memory_MemTotal_bytes     | node-exporter |

### `node:node_cpu_saturation_load1:`

Sumo query:

```text
#A: metric=node_load1
#B: metric=node_cpu_seconds_total | count by node,cpu | count by node
#C: #A / #B
```

Depends on the following metrics:

| name                   | source        |
| ---------------------- | ------------- |
| node_load1             | node-exporter |
| node_cpu_seconds_total | node-exporter |

### `node:node_cpu_utilisation:avg1m`

Sumo query:

```text
metric=node_cpu_seconds_total !mode=idle | rate increasing | avg by node
```

Depends on the following metrics:

| name                   | source        |
| ---------------------- | ------------- |
| node_cpu_seconds_total | node-exporter |

### `node:node_disk_saturation:avg_irate`

Sumo query:

```text
metric=node_disk_io_time_weighted_seconds_total | rate | avg by node
```

Depends on the following metrics:

| name                                     | source        |
| ---------------------------------------- | ------------- |
| node_disk_io_time_weighted_seconds_total | node-exporter |

### `node:node_disk_utilisation:avg_irate`

Sumo query:

```text
metric=node_disk_io_time_seconds_total | rate | avg by node
```

Depends on the following metrics:

| name                            | source        |
| ------------------------------- | ------------- |
| node_disk_io_time_seconds_total | node-exporter |

### `node:node_filesystem_avail:`

Sumo query:

```text
#A: cluster=kubernetes metric=node_filesystem_avail_bytes !fstype=tmpfs
#B: cluster=kubernetes metric=node_filesystem_size_bytes !fstype=tmpfs
#C: #A / #B  | max by node,namespace,pod,device
```

Depends on the following metrics:

| name                        | source        |
| --------------------------- | ------------- |
| node_filesystem_avail_bytes | node-exporter |
| node_filesystem_size_bytes  | node-exporter |

### `node:node_filesystem_usage:`

:construction:

Sumo query:

```text
#A: metric=node_filesystem_size_bytes !fstype=tmpfs  | sum by node
#B: metric=node_filesystem_avail_bytes !fstype=tmpfs | sum by node
#C: 1 - #A / #B
```

Depends on the following metrics:

| name                        | source        |
| --------------------------- | ------------- |
| node_filesystem_avail_bytes | node-exporter |
| node_filesystem_size_bytes  | node-exporter |

### `node:node_memory_bytes_total:sum`

Sumo query:

```text
metric=node_memory_MemTotal_bytes
```

Depends on the following metrics:

| name                       | source        |
| -------------------------- | ------------- |
| node_memory_MemTotal_bytes | node-exporter |

### `node:node_memory_swap_io_bytes:sum_rate`

Sumo query:

```text
#A: metric=node_vmstat_pgpgin | rate increasing
#B: metric=node_vmstat_pgpgout  | rate increasing
#C: (#A + #B) * 1000
```

Depends on the following metrics:

| name                | source        |
| ------------------- | ------------- |
| node_vmstat_pgpgin  | node-exporter |
| node_vmstat_pgpgout | node-exporter |

### `node:node_memory_utilisation:`

Sumo query:

```text
#A: metric=node_memory_MemFree_bytes
#B: metric=node_memory_Cached_bytes
#C: metric=node_memory_Buffers_bytes
#D: metric=node_memory_MemTotal_bytes
#E: 1 - ((#A + #B + #C) / #D)
```

Depends on the following metrics:

| name                       | source        |
| -------------------------- | ------------- |
| node_memory_MemFree_bytes  | node-exporter |
| node_memory_Cached_bytes   | node-exporter |
| node_memory_Buffers_bytes  | node-exporter |
| node_memory_MemTotal_bytes | node-exporter |

### `node:node_memory_utilisation:ratio`

Sumo query:

```text
#A: metric=node_memory_MemAvailable_bytes
#B: metric=node_memory_MemTotal_bytes
#C: 1 - #A / #B
```

Depends on the following metrics:

| name                           | source        |
| ------------------------------ | ------------- |
| node_memory_MemAvailable_bytes | node-exporter |
| node_memory_MemTotal_bytes     | node-exporter |

### `node:node_net_saturation:sum_irate`

Sumo query:

```text
#A: metric=node_network_receive_drop_total !device=veth* | rate | sum by node
#B: metric=node_network_transmit_drop_total !device=veth* | rate | sum by node
#C: #A + #B along node

```

Depends on the following metrics:

| name                             | source        |
| -------------------------------- | ------------- |
| node_network_receive_drop_total  | node-exporter |
| node_network_transmit_drop_total | node-exporter |

### `node:node_net_utilisation:sum_irate`

Sumo query:

```text
#A: metric=node_network_receive_bytes_total !device=veth* | rate | sum by node
#B: metric=node_network_transmit_bytes_total !device=veth* | rate | sum by node
#C: #A + #B along node
```

Depends on the following metrics:

| name                              | source        |
| --------------------------------- | ------------- |
| node_network_receive_bytes_total  | node-exporter |
| node_network_transmit_bytes_total | node-exporter |

### `node:node_num_cpu:sum`

Sumo query:

```text
cluster=kubernetes metric=node_cpu_seconds_total | count by node,cpu | count by node
```

Depends on the following metrics:

| name                   | source        |
| ---------------------- | ------------- |
| node_cpu_seconds_total | node-exporter |
