# Deployment Guide for unreleased version

This page has instructions for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level
metadata; and sending them to Sumo Logic. See our [documentation guide](https://help.sumologic.com/docs/observability/kubernetes/) for
details on our Kubernetes Solution.

- [Deployment Guide for unreleased version](#deployment-guide-for-unreleased-version)
  - [Solution overview](#solution-overview)
    - [Log Collection](#log-collection)
    - [Metrics Collection](#metrics-collection)
    - [Kubernetes Events Collection](#kubernetes-events-collection)
  - [Minimum Requirements](#minimum-requirements)
  - [Support Matrix](#support-matrix)
    - [ARM support](#arm-support)
    - [Falco support](#falco-support)

Documentation for other versions can be found in the
[main README file](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/README.md#documentation).

---

Documentation links:

- [Installation](https://help.sumologic.com/docs/send-data/kubernetes/install-helm-chart/)

- Configuration

  - [Examples](/docs/configuration-examples.md)
  - Logs
    - [Collecting container logs](https://help.sumologic.com/docs/send-data/kubernetes/collecting-logs/)
    - [Collecting Systemd logs](https://help.sumologic.com/docs/send-data/kubernetes/collecting-logs/)
  - Metrics
    - [Collecting Kubernetes metrics](https://help.sumologic.com/docs/send-data/kubernetes/collecting-metrics/#kubernetes-metrics)
    - [Collecting application metrics](https://help.sumologic.com/docs/send-data/kubernetes/collecting-metrics#filtering-metrics)
  - [Advanced Configuration/Best Practices](https://help.sumologic.com/docs/send-data/kubernetes/best-practices/)
  - [Advanced Configuration/Security best practices](https://help.sumologic.com/docs/send-data/kubernetes/security-best-practices/)
  - [Authenticating with container registry](/docs/working-with-container-registries.md#authenticating-with-container-registry)
    - [Using pull secrets with `sumologic-kubernetes-collection` helm chart](/docs/working-with-container-registries.md#authenticating-with-container-registry)
  - [Collecting Kubernetes events](https://help.sumologic.com/docs/send-data/kubernetes/collecting-events/)
  - Open Telemetry
    - [Open Telemetry with `sumologic-kubernetes-collection`](/docs/opentelemetry-collector/README.md)
    - [Traces - auto-instrumentation in Kubernetes](https://help.sumologic.com/docs/apm/traces/get-started-transaction-tracing/opentelemetry-instrumentation/kubernetes)
    - [OTLP source](/docs/otlp-source.md)

- Upgrades

  - [Upgrade from v3 to v4][migration-doc-v4]
  - [Upgrade from v2 to v3][migration-doc-v3]
  - [Upgrade from v2.17 to v2.18][migration-doc-v2.18]
  - [Upgrade from v1.3 to v2.0][migration-doc-v2]
  - [Upgrade from v0.17 to v1.0][migration-doc-v1]
  - [Migrate from `SumoLogic/fluentd-kubernetes-sumologic`][migration-steps]

- [Troubleshooting Collection](https://help.sumologic.com/docs/send-data/kubernetes/troubleshoot-collection/)
- [Monitoring the Monitoring](/docs/monitoring-lag.md)
- [Dev Releases](/docs/dev.md)

[migration-doc-v4]: https://help.sumologic.com/docs/send-data/kubernetes/v4/important-changes/
[migration-doc-v3]: https://help.sumologic.com/docs/send-data/kubernetes/v3/important-changes/
[migration-doc-v2.18]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v2-18-migration.md
[migration-doc-v2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v2_migration_doc.md
[migration-doc-v1]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/v1_migration_doc.md
[migration-steps]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/Migration_Steps.md

## Solution overview

The diagrams below illustrate the components of the Kubernetes collection solution.

### Log Collection

![logs](/images/logs.png)

### Metrics Collection

![metrics](/images/metrics.png)

### Kubernetes Events Collection

![events](/images/events.png)

## Minimum Requirements

| Name | Version |
| ---- | ------- |
| K8s  | 1.21+   |
| Helm | 3.5+    |

## Support Matrix

The following table displays the tested Kubernetes and Helm versions.

| Name                   | Version                                  |
| ---------------------- | ---------------------------------------- |
| K8s with EKS           | 1.25<br/>1.26<br/>1.27<br/>1.28<br/>1.29 |
| K8s with EKS (fargate) | 1.25<br/>1.26<br/>1.27<br/>1.28<br/>1.29 |
| K8s with Kops          | 1.25<br/>1.26<br/>1.27<br/>1.28<br/>1.29 |
| K8s with GKE           | 1.25<br/>1.26<br/>1.27<br/>1.28<br/>1.29 |
| K8s with AKS           | 1.25<br/>1.26<br/>1.27<br/>1.28<br/>1.29 |
| OpenShift              | 4.12<br/>4.13<br/>4.14                   |
| Helm                   | 3.8.2 (Linux)                            |
| kubectl                | 1.23.6                                   |

The following table displays the currently used software versions for our Helm chart.

| Name                                      | Version |
| ----------------------------------------- | ------- |
| OpenTelemetry Collector                   | 0.92.0  |
| OpenTelemetry Operator                    | 0.47.1  |
| kube-prometheus-stack/Prometheus Operator | 40.5.0  |
| Falco                                     | 3.8.7   |
| Telegraf Operator                         | 1.3.12  |
| Tailing Sidecar Operator                  | 0.10.0  |
| Metrics Server                            | 6.11.2  |

### ARM support

The collection Helm Chart supports AWS Graviton CPUs, and has been tested in ARM-based EKS clusters. In principle, it should run fine on any
ARM64 node, but there is currently no official support for non-AWS ARM environments. If you do however run into problems in such an
environment, don't hesitate to open an [issue][issues] describing them.

[issues]: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues

### Falco support

Falco is embedded in this Helm Chart for user convenience only - Sumo Logic does not provide production support for it.

### Windows nodes support

Support for Windows is experimental.

Windows nodes are supported only for metrics collection. To enable it, add the following configuration to your `user-values.yaml`

```yaml
prometheus-windows-exporter:
  enabled: true
```

It will send `windows_` prefixed metrics to Sumo Logic.

<details><summary>List of metrics:</summary>

```text
go_gc_duration_seconds summary
go_goroutines gauge
go_info gauge
go_memstats_alloc_bytes gauge
go_memstats_alloc_bytes_total counter
go_memstats_buck_hash_sys_bytes gauge
go_memstats_frees_total counter
go_memstats_gc_sys_bytes gauge
go_memstats_heap_alloc_bytes gauge
go_memstats_heap_idle_bytes gauge
go_memstats_heap_inuse_bytes gauge
go_memstats_heap_objects gauge
go_memstats_heap_released_bytes gauge
go_memstats_heap_sys_bytes gauge
go_memstats_last_gc_time_seconds gauge
go_memstats_lookups_total counter
go_memstats_mallocs_total counter
go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_sys_bytes gauge
go_memstats_mspan_inuse_bytes gauge
go_memstats_mspan_sys_bytes gauge
go_memstats_next_gc_bytes gauge
go_memstats_other_sys_bytes gauge
go_memstats_stack_inuse_bytes gauge
go_memstats_stack_sys_bytes gauge
go_memstats_sys_bytes gauge
go_threads gauge
process_cpu_seconds_total counter
process_max_fds gauge
process_open_fds gauge
process_resident_memory_bytes gauge
process_start_time_seconds gauge
process_virtual_memory_bytes gauge
windows_container_available counter
windows_container_count gauge
windows_container_cpu_usage_seconds_kernelmode counter
windows_container_cpu_usage_seconds_total counter
windows_container_cpu_usage_seconds_usermode counter
windows_container_memory_usage_commit_bytes gauge
windows_container_memory_usage_commit_peak_bytes gauge
windows_container_memory_usage_private_working_set_bytes gauge
windows_container_network_receive_bytes_total counter
windows_container_network_receive_packets_dropped_total counter
windows_container_network_receive_packets_total counter
windows_container_network_transmit_bytes_total counter
windows_container_network_transmit_packets_dropped_total counter
windows_container_network_transmit_packets_total counter
windows_container_storage_read_count_normalized_total counter
windows_container_storage_read_size_bytes_total counter
windows_container_storage_write_count_normalized_total counter
windows_container_storage_write_size_bytes_total counter
windows_cpu_clock_interrupts_total counter
windows_cpu_core_frequency_mhz gauge
windows_cpu_cstate_seconds_total counter
windows_cpu_dpcs_total counter
windows_cpu_idle_break_events_total counter
windows_cpu_interrupts_total counter
windows_cpu_parking_status gauge
windows_cpu_processor_mperf_total counter
windows_cpu_processor_performance_total counter
windows_cpu_processor_privileged_utility_total counter
windows_cpu_processor_rtc_total counter
windows_cpu_processor_utility_total counter
windows_cpu_time_total counter
windows_cs_hostname gauge
windows_cs_logical_processors gauge
windows_cs_physical_memory_bytes gauge
windows_exporter_build_info gauge
windows_exporter_collector_duration_seconds gauge
windows_exporter_collector_success gauge
windows_exporter_collector_timeout gauge
windows_exporter_perflib_snapshot_duration_seconds gauge
windows_logical_disk_avg_read_requests_queued gauge
windows_logical_disk_avg_write_requests_queued gauge
windows_logical_disk_free_bytes gauge
windows_logical_disk_idle_seconds_total counter
windows_logical_disk_read_bytes_total counter
windows_logical_disk_read_latency_seconds_total counter
windows_logical_disk_read_seconds_total counter
windows_logical_disk_read_write_latency_seconds_total counter
windows_logical_disk_reads_total counter
windows_logical_disk_requests_queued gauge
windows_logical_disk_size_bytes gauge
windows_logical_disk_split_ios_total counter
windows_logical_disk_write_bytes_total counter
windows_logical_disk_write_latency_seconds_total counter
windows_logical_disk_write_seconds_total counter
windows_logical_disk_writes_total counter
windows_memory_available_bytes gauge
windows_memory_cache_bytes gauge
windows_memory_cache_bytes_peak gauge
windows_memory_cache_faults_total counter
windows_memory_commit_limit gauge
windows_memory_committed_bytes gauge
windows_memory_demand_zero_faults_total counter
windows_memory_free_and_zero_page_list_bytes gauge
windows_memory_free_system_page_table_entries gauge
windows_memory_modified_page_list_bytes gauge
windows_memory_page_faults_total counter
windows_memory_pool_nonpaged_allocs_total gauge
windows_memory_pool_nonpaged_bytes gauge
windows_memory_pool_paged_allocs_total counter
windows_memory_pool_paged_bytes gauge
windows_memory_pool_paged_resident_bytes gauge
windows_memory_standby_cache_core_bytes gauge
windows_memory_standby_cache_normal_priority_bytes gauge
windows_memory_standby_cache_reserve_bytes gauge
windows_memory_swap_page_operations_total counter
windows_memory_swap_page_reads_total counter
windows_memory_swap_page_writes_total counter
windows_memory_swap_pages_read_total counter
windows_memory_swap_pages_written_total counter
windows_memory_system_cache_resident_bytes gauge
windows_memory_system_code_resident_bytes gauge
windows_memory_system_code_total_bytes gauge
windows_memory_system_driver_resident_bytes gauge
windows_memory_system_driver_total_bytes gauge
windows_memory_transition_faults_total counter
windows_memory_transition_pages_repurposed_total counter
windows_memory_write_copies_total counter
windows_net_bytes_received_total counter
windows_net_bytes_sent_total counter
windows_net_bytes_total counter
windows_net_current_bandwidth_bytes gauge
windows_net_output_queue_length_packets gauge
windows_net_packets_outbound_discarded_total counter
windows_net_packets_outbound_errors_total counter
windows_net_packets_received_discarded_total counter
windows_net_packets_received_errors_total counter
windows_net_packets_received_total counter
windows_net_packets_received_unknown_total counter
windows_net_packets_sent_total counter
windows_net_packets_total counter
windows_os_info gauge
windows_os_paging_free_bytes gauge
windows_os_paging_limit_bytes gauge
windows_os_physical_memory_free_bytes gauge
windows_os_process_memory_limit_bytes gauge
windows_os_processes gauge
windows_os_processes_limit gauge
windows_os_time gauge
windows_os_timezone gauge
windows_os_users gauge
windows_os_virtual_memory_bytes gauge
windows_os_virtual_memory_free_bytes gauge
windows_os_visible_memory_bytes gauge
windows_physical_disk_idle_seconds_total counter
windows_physical_disk_read_bytes_total counter
windows_physical_disk_read_latency_seconds_total counter
windows_physical_disk_read_seconds_total counter
windows_physical_disk_read_write_latency_seconds_total counter
windows_physical_disk_reads_total counter
windows_physical_disk_requests_queued gauge
windows_physical_disk_split_ios_total counter
windows_physical_disk_write_bytes_total counter
windows_physical_disk_write_latency_seconds_total counter
windows_physical_disk_write_seconds_total counter
windows_physical_disk_writes_total counter
windows_service_info gauge
windows_service_start_mode gauge
windows_service_state gauge
windows_service_status gauge
windows_system_context_switches_total counter
windows_system_exception_dispatches_total counter
windows_system_processor_queue_length gauge
windows_system_system_calls_total counter
windows_system_system_up_time gauge
windows_system_threads gauge
windows_textfile_scrape_error gauge
```

</details>

> [!NOTE] We currently do not have dashboards using these metrics.
