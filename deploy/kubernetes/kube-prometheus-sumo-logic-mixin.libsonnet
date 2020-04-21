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
            regex: "kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_deployment_spec_replicas|kube_deployment_status_replicas_available|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)",
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
            regex: "kube-scheduler;scheduler_(?:e2e_scheduling|binding|scheduling_algorithm)_latency_microseconds.*",
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
            regex: "apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_(?:latencies|duration_seconds).*|etcd_request_cache_get_(?:latencies_summary|duration_seconds).*|etcd_request_cache_add_(?:latencies_summary|duration_seconds).*|etcd_helper_cache_hit_(?:count|total)|etcd_helper_cache_miss_(?:count|total))",
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
            regex: "kubelet;(?:kubelet_docker_operations_errors.*|kubelet_docker_operations_(?:latency_micro|duration_)seconds.*|kubelet_running_container_count|kubelet_running_pod_count|kubelet_runtime_operations_(?:latency_micro|duration_)seconds.*)",
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
            regex: "kubelet;.+;(?:container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_fs_usage_bytes|container_fs_limit_bytes)",
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
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.control-plane",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "coredns",
            sourceLabels: [
              "job"
            ]
          }
        ]
      },
      {
        url: $._config.sumologicCollectorSvc + "prometheus.metrics.control-plane",
        writeRelabelConfigs: [
          {
            action: "keep",
            regex: "kube-etcd",
            sourceLabels: [
              "job"
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
