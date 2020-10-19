{
  _config+:: {
    sumologicCollectorSvc: 'http://collection-sumologic.sumologic.svc.cluster.local:9888/',
    clusterName: "kubernetes"
  },
  sumologicCollector:: {
    remoteWriteConfigs+: [
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.state",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_deployment_spec_replicas|kube_deployment_status_replicas_available|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_hpa_spec_max_replicas|kube_hpa_spec_min_replicas|kube_hpa_status_current_replicas|kube_hpa_status_desired_replicas)",
            sourceLabels: [
              "job",
              "__name__"
            ]
          },
          {
            action: "labelmap",
            regex: "(pod|service)",
            replacement: "service_discovery_${1}"
          },
          {
            action: "labeldrop",
            regex: "(pod|service)"
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.state",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kube-state-metrics;(?:kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.controller-manager",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kubelet;cloudprovider_.*_api_request_duration_seconds.*",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.scheduler",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kube-scheduler;scheduler_(?:e2e_scheduling|binding|scheduling_algorithm)_duration_seconds.*",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.apiserver",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_(?:duration_seconds|latencies)_(?:count|sum)|apiserver_request_latencies_summary(?:|_count|_sum)|etcd_request_cache_(?:add|get)_(?:duration_seconds|latencies_summary)_(?:count|sum)|etcd_helper_cache_(?:hit|miss)_(?:count|total))",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.kubelet",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kubelet;(?:kubelet_docker_operations_errors(?:|_total)|kubelet_(?:docker|runtime)_operations_duration_seconds_(?:count|sum)|kubelet_running_(?:container|pod)_count|kubelet_(:?docker|runtime)_operations_latency_microseconds(?:|_count|_sum))",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.container",
        writeRelabelConfigs: [
          {
            action: "labelmap",
            regex: "container_name",
            replacement: "container"
          },
          {
            action: "drop",
            regex: "POD",
            sourceLabels: [
              "container"
            ]
          },
          {
            action: "keep",
            regex: "kubelet;.+;(?:container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_fs_usage_bytes|container_fs_limit_bytes|container_cpu_cfs_throttled_seconds_total)",
            sourceLabels: [
              "job",
              "container",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.container",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kubelet;(?:container_network_receive_bytes_total|container_network_transmit_bytes_total)",
            sourceLabels: [
              "job",
              "__name__"
            ]
          },
          {
            action: "labeldrop",
            regex: "container"
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.node",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "node-exporter;(?:node_load1|node_load5|node_load15|node_cpu_seconds_total)",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.operator.rule",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:",
            sourceLabels: [
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "(?:up|prometheus_remote_storage_.*|fluentd_.*|fluentbit.*|otelcol.*)",
            sourceLabels: [
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.control-plane.coredns",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "coredns;(?:coredns_cache_(size|(hits|misses)_total)|coredns_dns_request_duration_seconds_(count|sum)|coredns_(dns_request|dns_response_rcode|forward_request)_count_total|process_(cpu_seconds_total|open_fds|resident_memory_bytes))",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.control-plane.kube-etcd",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kube-etcd;(?:etcd_debugging_(mvcc_db_total_size_in_bytes|store_(expires_total|watchers))|etcd_disk_(backend_commit|wal_fsync)_duration_seconds_bucket|etcd_grpc_proxy_cache_(hits|misses)_total|etcd_network_client_grpc_(received|sent)_bytes_total|etcd_server_(has_leader|leader_changes_seen_total)|etcd_server_proposals_(pending|(applied|committed|failed)_total)|process_(cpu_seconds_total|open_fds|resident_memory_bytes))",
            sourceLabels: [
              "job",
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.applications.nginx-ingress",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "(?:nginx_ingress_controller_ingress_resources_total|nginx_ingress_controller_nginx_(last_reload_(milliseconds|status)|reload(s|_errors)_total)|nginx_ingress_controller_virtualserver(|route)_resources_total|nginx_ingress_nginx_connections_(accepted|active|handled|reading|waiting|writing)|nginx_ingress_nginx_http_requests_total)",
            sourceLabels: [
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.applications.nginx",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "(?:nginx_(accepts|active|handled|reading|requests|waiting|writing))",
            sourceLabels: [
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.applications.redis",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "(?:redis_((blocked_|)clients|cluster_enabled|cmdstat_calls|connected_slaves|(evicted|expired|tracking_total)_keys|instantaneous_ops_per_sec|keyspace_(hitrate|hits|misses)|(master|slave)_repl_offset|maxmemory|mem_fragmentation_(bytes|ratio)|rdb_changes_since_last_save|rejected_connections|total_commands_processed|total_net_(input|output)_bytes|uptime|used_(cpu_(sys|user)|memory(_overhead|_rss|_startup|))))",
            sourceLabels: [
              "__name__"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.applications.jmx",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "(?:java_lang_(ClassLoading_(TotalL|Unl|L)oadedClassCount|Compilation_TotalCompilationTime|GarbageCollector_(Collection(Count|Time)|LastGcInfo_(GcThreadCount|duration|(memoryU|u)sage(After|Before)Gc_.*_used))|MemoryPool_(CollectionUsage(ThresholdSupported|_committed|_max|_used)|(Peak|)Usage_(committed|max|used)|UsageThresholdSupported)|Memory_((Non|)HeapMemoryUsage_(committed|max|used)|ObjectPendingFinalizationCount)|OperatingSystem_(AvailableProcessors|(CommittedVirtual|(Free|Total)(Physical|))MemorySize|(Free|Total)SwapSpaceSize|(Max|Open)FileDescriptorCount|ProcessCpu(Load|Time)|System(CpuLoad|LoadAverage))|Runtime_(BootClassPathSupported|Pid|Uptime|StartTime)|Threading_(CurrentThread(AllocatedBytes|(Cpu|User)Time)|(Daemon|Peak|TotalStarted|)ThreadCount|(ObjectMonitor|Synchronizer)UsageSupported|Thread(AllocatedMemory.*|ContentionMonitoring.*|CpuTime.*))))",
            sourceLabels: [
              "__name__"
            ]
          }
        ]
      }
    ],
  },
  prometheus+:: {
    prometheus+: {
      spec+: {
        remoteWrite+: $.sumologicCollector.remoteWriteConfigs,
        externalLabels+: {
          cluster: $._config.clusterName,
        },
      },
    },
  },
}
