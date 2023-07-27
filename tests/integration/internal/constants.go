package internal

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"
)

const (
	_helmSumoLogicChartRelPath = "../../deploy/helm/sumologic/"
	_kindImagesJSONPath        = "kind_images.json"

	EnvNameKindImage = "KIND_NODE_IMAGE"

	YamlPathReceiverMock = "yamls/receiver-mock.yaml"

	// default cluster name in Helm chart Config
	// TODO: read this from values.yaml used for the test directly
	ClusterName = "kubernetes"

	ReceiverMockServicePort = 3000
	ReceiverMockServiceName = "receiver-mock"
	ReceiverMockNamespace   = "receiver-mock"

	LogsGeneratorNamespace = "logs-generator"
	LogsGeneratorName      = "logs-generator"
	LogsGeneratorImage     = "sumologic/kubernetes-tools:2.14.0"

	OverrideNamespace = "test-override"

	TracesGeneratorNamespace = "customer-trace-tester"
	TracesGeneratorName      = "customer-trace-tester"
	TracesGeneratorImage     = "sumologic/kubernetes-tools:2.14.0"

	MultilineLogsNamespace = "multiline-logs-generator"
	MultilineLogsPodName   = "multiline-logs-generator"
	MultilineLogsGenerator = "yamls/multiline-logs-generator.yaml"

	TailingSidecarTestNamespace      = "tailing-sidecar"
	TailingSidecarTest               = "yamls/tailing-sidecar-test.yaml"
	TailingSidecarTestDeploymentName = "test-tailing-sidecar-operator"

	NginxTelegrafMetricsTest = "yamls/nginx.yaml"
	NginxTelegrafNamespace   = "nginx"

	// useful regular expressions for matching metadata
	PodDeploymentSuffixRegex = "-[a-z0-9]{9,10}-[a-z0-9]{4,5}" // the Pod suffix for Deployments
	PodDaemonSetSuffixRegex  = "-[a-z0-9]{4,5}"
	NetworkPortRegex         = "\\d{1,5}"
	IpRegex                  = "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}"
	IpWithPortRegex          = "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{1,5}"
	NodeNameRegex            = ".*-control-plane" // node name for KinD TODO: get this from the cluster directly instead
	NotUndefinedRegex        = "(?!undefined$).*"
	EmptyRegex               = "^$"
)

// metrics we expect the receiver to get
// metrics which are expected in current E2E tests but aren't present here, are commented out
// TODO: figure out why the expected metrics aren't present
var (
	KubeStateMetrics = []string{
		"kube_statefulset_status_observed_generation",
		"kube_statefulset_status_replicas",
		"kube_statefulset_replicas",
		"kube_statefulset_metadata_generation",
	}
	KubeDaemonSetMetrics = []string{
		"kube_daemonset_status_current_number_scheduled",
		"kube_daemonset_status_desired_number_scheduled",
		"kube_daemonset_status_number_misscheduled",
		"kube_daemonset_status_number_unavailable",
	}
	KubeDeploymentMetrics = []string{
		"kube_deployment_status_replicas_available",
		"kube_deployment_status_replicas_unavailable",
		"kube_deployment_spec_replicas",
	}
	KubeNodeMetrics = []string{
		"kube_node_info",
		"kube_node_status_allocatable",
		"kube_node_status_capacity",
		"kube_node_status_condition",
	}
	KubePodMetrics = []string{
		"kube_pod_container_info",
		"kube_pod_container_resource_requests",
		"kube_pod_container_resource_limits",
		"kube_pod_container_status_ready",
		// No container is being terminated,
		// so metric is not being generated
		// "kube_pod_container_status_terminated_reason",
		"kube_pod_container_status_restarts_total",
		"kube_pod_status_phase",
	}
	// These metrics are collected by Prometheus, but only used for recording rules
	// Otel actually sends these to the remote
	AdditionalKubePodMetrics = []string{
		"kube_pod_info",
	}
	KubeServiceMetrics = []string{
		"kube_service_info",
		"kube_service_spec_type",
	}
	KubeletMetrics = []string{
		"kubelet_running_containers",
		"kubelet_running_pods",
		"kubelet_runtime_operations_duration_seconds_count",
		"kubelet_runtime_operations_duration_seconds_sum",
	}
	KubeSchedulerMetrics = []string{
		"scheduler_scheduling_algorithm_duration_seconds_count",
		"scheduler_scheduling_algorithm_duration_seconds_sum",
		"scheduler_scheduling_algorithm_duration_seconds_bucket",
		"scheduler_framework_extension_point_duration_seconds_bucket",
		"scheduler_framework_extension_point_duration_seconds_count",
		"scheduler_framework_extension_point_duration_seconds_sum",
	}
	KubeApiServerMetrics = []string{
		"apiserver_request_total",
		"apiserver_request_duration_seconds_count",
		"apiserver_request_duration_seconds_sum",
	}
	KubeEtcdMetrics = []string{
		"etcd_mvcc_db_total_size_in_bytes",
		"etcd_debugging_store_expires_total",
		"etcd_debugging_store_watchers",
		"etcd_disk_backend_commit_duration_seconds_bucket",
		"etcd_disk_backend_commit_duration_seconds_count",
		"etcd_disk_backend_commit_duration_seconds_sum",
		"etcd_disk_wal_fsync_duration_seconds_bucket",
		"etcd_disk_wal_fsync_duration_seconds_count",
		"etcd_disk_wal_fsync_duration_seconds_sum",
		"etcd_grpc_proxy_cache_hits_total",
		"etcd_grpc_proxy_cache_misses_total",
		"etcd_network_client_grpc_received_bytes_total",
		"etcd_network_client_grpc_sent_bytes_total",
		"etcd_server_has_leader",
		"etcd_server_leader_changes_seen_total",
		"etcd_server_proposals_applied_total",
		"etcd_server_proposals_committed_total",
		"etcd_server_proposals_failed_total",
		"etcd_server_proposals_pending",
		"process_cpu_seconds_total",
		"process_open_fds",
		"process_resident_memory_bytes",
	}
	KubeControllerManagerMetrics = []string{
		// we only collect AWS-specific metrics here
	}
	CoreDNSMetrics = []string{
		"coredns_cache_entries",
		"coredns_cache_hits_total",
		"coredns_cache_misses_total",
		"coredns_dns_request_duration_seconds_count",
		"coredns_dns_request_duration_seconds_sum",
		"coredns_dns_requests_total",
		"coredns_dns_responses_total",
		"coredns_forward_requests_total",
		"process_cpu_seconds_total",
		"process_open_fds",
		"process_resident_memory_bytes",
	}
	CAdvisorMetrics = []string{
		"container_cpu_usage_seconds_total",
		"container_cpu_cfs_throttled_seconds_total",
		// These metrics will be available in containerd after kind upgrades past
		// https://github.com/containerd/containerd/issues/5882
		// "container_fs_usage_bytes",
		// "container_fs_limit_bytes",
		"container_network_receive_bytes_total",
		"container_memory_working_set_bytes",
		"container_network_transmit_bytes_total",
	}
	NodeExporterMetrics = []string{
		"node_load1",
		"node_load5",
		"node_load15",
		"node_cpu_seconds_total",
	}
	// These metrics are collected by Prometheus, but only used for recording rules
	// Otel actually sends these to the remote
	AdditionalNodeExporterMetrics = []string{
		"node_disk_io_time_weighted_seconds_total",
		"node_disk_io_time_seconds_total",
		"node_vmstat_pgpgin",
		"node_vmstat_pgpgout",
		"node_memory_MemFree_bytes",
		"node_memory_Cached_bytes",
		"node_memory_Buffers_bytes",
		"node_memory_MemTotal_bytes",
		"node_network_receive_drop_total",
		"node_network_transmit_drop_total",
		"node_network_receive_bytes_total",
		"node_network_transmit_bytes_total",
		"node_filesystem_avail_bytes",
		"node_filesystem_size_bytes",
	}
	DefaultOtelcolMetrics = []string{
		"otelcol_process_cpu_seconds",
		"otelcol_process_memory_rss",
		"otelcol_process_runtime_heap_alloc_bytes",
		"otelcol_process_runtime_total_alloc_bytes",
		"otelcol_process_runtime_total_sys_memory_bytes",
		"otelcol_process_uptime",
		"otelcol_exporter_enqueue_failed_metric_points",
		"otelcol_exporter_enqueue_failed_spans",
		"otelcol_exporter_enqueue_failed_log_records",
		"otelcol_exporter_queue_capacity",
		"otelcol_exporter_queue_size",
		"otelcol_exporter_requests_bytes",
		"otelcol_exporter_requests_duration",
		"otelcol_exporter_requests_records",
		"otelcol_exporter_requests_sent",
		"otelcol_exporter_sent_metric_points",
		"otelcol_otelsvc_k8s_other_added",
		"otelcol_otelsvc_k8s_other_updated",
		"otelcol_otelsvc_k8s_pod_added",
		"otelcol_otelsvc_k8s_pod_table_size",
		"otelcol_otelsvc_k8s_pod_updated",
		"otelcol_processor_accepted_metric_points",
		"otelcol_processor_batch_batch_send_size_bucket",
		"otelcol_processor_batch_batch_send_size_count",
		"otelcol_processor_batch_batch_send_size_sum",
		"otelcol_processor_batch_timeout_trigger_send",
		"otelcol_processor_dropped_metric_points",
		"otelcol_processor_groupbyattrs_metric_groups_bucket",
		"otelcol_processor_groupbyattrs_metric_groups_count",
		"otelcol_processor_groupbyattrs_metric_groups_sum",
		"otelcol_processor_groupbyattrs_num_non_grouped_metrics",
		"otelcol_processor_refused_metric_points",
	}
	LogsOtelcolMetrics = []string{
		"otelcol_exporter_sent_log_records",
		"otelcol_receiver_accepted_log_records",
		"otelcol_processor_accepted_log_records",
		"otelcol_receiver_refused_log_records",
		"otelcol_processor_refused_log_records",
		"otelcol_processor_dropped_log_records",
		"otelcol_processor_groupbyattrs_num_grouped_logs",
		"otelcol_processor_groupbyattrs_log_groups_bucket",
		"otelcol_processor_groupbyattrs_log_groups_count",
		"otelcol_processor_groupbyattrs_log_groups_sum",
	}
	TracingOtelcolMetrics = []string{
		"otelcol_loadbalancer_num_backend_updates",
		"otelcol_loadbalancer_num_backends",
		"otelcol_loadbalancer_num_resolutions",
	}
	MetricsCollectorOtelcolMetrics = []string{
		"otelcol_receiver_refused_metric_points",
		"otelcol_processor_groupbyattrs_num_grouped_metrics",
		"otelcol_receiver_accepted_metric_points",
	}
	PrometheusMetrics = []string{
		"prometheus_remote_storage_bytes_total",
		"prometheus_remote_storage_enqueue_retries_total",
		"prometheus_remote_storage_exemplars_dropped_total",
		"prometheus_remote_storage_exemplars_failed_total",
		"prometheus_remote_storage_exemplars_in_total",
		"prometheus_remote_storage_exemplars_pending",
		"prometheus_remote_storage_exemplars_retried_total",
		"prometheus_remote_storage_exemplars_total",
		"prometheus_remote_storage_highest_timestamp_in_seconds",
		"prometheus_remote_storage_max_samples_per_send",
		"prometheus_remote_storage_metadata_bytes_total",
		"prometheus_remote_storage_metadata_failed_total",
		"prometheus_remote_storage_metadata_retried_total",
		"prometheus_remote_storage_metadata_total",
		"prometheus_remote_storage_queue_highest_sent_timestamp_seconds",
		"prometheus_remote_storage_samples_dropped_total",
		"prometheus_remote_storage_samples_failed_total",
		"prometheus_remote_storage_samples_in_total",
		"prometheus_remote_storage_samples_pending",
		"prometheus_remote_storage_samples_retried_total",
		"prometheus_remote_storage_samples_total",
		"prometheus_remote_storage_sent_batch_duration_seconds_bucket",
		"prometheus_remote_storage_sent_batch_duration_seconds_count",
		"prometheus_remote_storage_sent_batch_duration_seconds_sum",
		"prometheus_remote_storage_shard_capacity",
		"prometheus_remote_storage_shards",
		"prometheus_remote_storage_shards_desired",
		"prometheus_remote_storage_shards_max",
		"prometheus_remote_storage_shards_min",
		"prometheus_remote_storage_string_interner_zero_reference_releases_total",
	}
	FluentBitMetrics = []string{
		"fluentbit_build_info",
		"fluentbit_filter_add_records_total",
		"fluentbit_filter_bytes_total",
		"fluentbit_filter_drop_records_total",
		"fluentbit_filter_records_total",
		"fluentbit_input_bytes_total",
		"fluentbit_input_files_closed_total",
		"fluentbit_input_files_opened_total",
		"fluentbit_input_files_rotated_total",
		"fluentbit_input_records_total",
		"fluentbit_output_dropped_records_total",
		"fluentbit_output_errors_total",
		"fluentbit_output_proc_bytes_total",
		"fluentbit_output_proc_records_total",
		"fluentbit_output_retried_records_total",
		"fluentbit_output_retries_failed_total",
		"fluentbit_output_retries_total",
		"fluentbit_uptime",
	}
	FluentDMetrics = []string{
		"fluentd_output_status_buffer_available_space_ratio",
		"fluentd_output_status_buffer_queue_length",
		"fluentd_output_status_buffer_stage_byte_size",
		"fluentd_output_status_buffer_stage_length",
		"fluentd_output_status_buffer_total_bytes",
		"fluentd_output_status_emit_count",
		"fluentd_output_status_emit_records",
		"fluentd_output_status_flush_time_count",
		"fluentd_output_status_num_errors",
		"fluentd_output_status_queue_byte_size",
		"fluentd_output_status_retry_count",
		"fluentd_output_status_retry_wait",
		"fluentd_output_status_rollback_count",
		"fluentd_output_status_slow_flush_count",
		"fluentd_output_status_write_count",
	}
	RecordingRuleMetrics = []string{
		":kube_pod_info_node_count:",
		"node:node_num_cpu:sum",
		"node_namespace_pod:kube_pod_info:",
		"node:node_cpu_utilisation:avg1m",
		":node_memory_utilisation:",
		// "node:node_memory_bytes_available:sum", // not present, depends on other recording rules that don't exist
		"node:node_memory_utilisation:ratio",
		"node:node_memory_utilisation:",
		"node:node_memory_utilisation_2:",
		"node:node_filesystem_usage:",
		"node:node_memory_bytes_total:sum",
		":node_net_utilisation:sum_irate",
		"node:node_net_utilisation:sum_irate",
		":node_net_saturation:sum_irate",
		"node:node_net_saturation:sum_irate",
		":node_cpu_utilisation:avg1m",
		":node_cpu_saturation_load1:",
		":node_disk_saturation:avg_irate",
		"node:node_disk_saturation:avg_irate",
		":node_disk_utilisation:avg_irate",
		"node:node_disk_utilisation:avg_irate",
		":node_memory_swap_io_bytes:sum_rate",
		"node:node_memory_swap_io_bytes:sum_rate",
		"node:cluster_cpu_utilisation:ratio",
		"node:cluster_memory_utilisation:ratio",
		"node:node_cpu_saturation_load1:",
		"node:node_filesystem_avail:",
		// "node:node_inodes_total:", // looks like we're not collecting node_filesystem_files which this requires
		// "node:node_inodes_free:",  // looks like we're not collecting node_filesystem_files_free which this requires
		"instance:node_network_receive_bytes:rate:sum",
	}
	// The receiver-mock Pod used for tests has a "prometheus.io/scrape: true" annotation
	// TODO: remove this once we have a better test for this behaviour
	ReceiverMockMetrics = []string{
		"receiver_mock_metrics_count",
		"receiver_mock_logs_count",
		"scrape_series_added",
		"scrape_samples_scraped",
		"scrape_samples_post_metric_relabeling",
		"scrape_duration_seconds",
	}
	OtherMetrics = []string{
		"up",
	}
	// these metrics may or may not show up depending on the specifics of the test
	// we accept them, but don't fail if they're not present
	FlakyMetrics = []string{
		"otelcol_otelsvc_k8s_pod_deleted",
		"otelcol_processor_batch_batch_size_trigger_send",
		"otelcol_otelsvc_k8s_ip_lookup_miss",
		"otelcol_otelsvc_k8s_other_deleted",
		"kube_pod_container_status_waiting_reason",
		// TODO: check different metrics depending on K8s version
		// scheduler_scheduling_duration_seconds is present for K8s <1.23
		// scheduler_scheduling_attempt_duration_seconds is present for K8s >=1.23
		"scheduler_e2e_scheduling_duration_seconds_count",
		"scheduler_e2e_scheduling_duration_seconds_sum",
		"scheduler_e2e_scheduling_duration_seconds_bucket",
		"scheduler_scheduling_attempt_duration_seconds_count",
		"scheduler_scheduling_attempt_duration_seconds_sum",
		"scheduler_scheduling_attempt_duration_seconds_bucket",
		"cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile",
		// TODO: Remove this once we have a better test for annotation metrics
		"receiver_mock_logs_ip_count",
		"receiver_mock_logs_bytes_count",
		"receiver_mock_logs_bytes_ip_count",
		"receiver_mock_metrics_ip_count",
	}

	NginxMetrics = []string{
		"nginx_accepts",
		"nginx_active",
		"nginx_handled",
		"nginx_reading",
		"nginx_requests",
		"nginx_waiting",
		"nginx_writing",
	}
)

var (
	HelmSumoLogicChartAbsPath    string
	KindImages                   KindImagesSpec
	DefaultExpectedMetricsGroups = [][]string{
		KubeStateMetrics,
		KubeDaemonSetMetrics,
		KubeDeploymentMetrics,
		KubeNodeMetrics,
		KubePodMetrics,
		KubeServiceMetrics,
		KubeletMetrics,
		KubeSchedulerMetrics,
		KubeApiServerMetrics,
		KubeEtcdMetrics,
		KubeControllerManagerMetrics,
		CoreDNSMetrics,
		CAdvisorMetrics,
		NodeExporterMetrics,
		PrometheusMetrics,
		RecordingRuleMetrics,
		ReceiverMockMetrics,
		OtherMetrics,
	}
	DefaultExpectedMetrics                 []string
	DefaultExpectedFluentdFluentbitMetrics []string
)

type KindImagesSpec struct {
	Supported []string `json:"supported"`
	Default   string   `json:"default"`
}

func InitializeConstants() error {
	var err error
	HelmSumoLogicChartAbsPath, err = filepath.Abs(_helmSumoLogicChartRelPath)
	if err != nil {
		return err
	}

	b, err := os.ReadFile(_kindImagesJSONPath)
	if err != nil {
		return err
	}
	if err = json.Unmarshal(b, &KindImages); err != nil {
		return err
	}

	DefaultExpectedFluentdFluentbitMetrics = []string{}
	for _, metrics := range append(DefaultExpectedMetricsGroups, FluentBitMetrics, FluentDMetrics) {
		DefaultExpectedFluentdFluentbitMetrics = append(DefaultExpectedFluentdFluentbitMetrics, metrics...)
	}

	DefaultExpectedMetrics = []string{}
	metricsGroupsWithOtelcol := append(DefaultExpectedMetricsGroups, DefaultOtelcolMetrics, LogsOtelcolMetrics)
	for _, metrics := range metricsGroupsWithOtelcol {
		DefaultExpectedMetrics = append(DefaultExpectedMetrics, metrics...)
	}

	log.Printf("Successfully read kind images spec")
	log.Printf("Default kind image: %v", KindImages.Default)
	log.Printf("Supported kind images: %v", KindImages.Supported)
	return nil
}
