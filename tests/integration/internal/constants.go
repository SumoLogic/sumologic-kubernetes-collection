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

	TracesGeneratorNamespace = "customer-trace-tester"
	TracesGeneratorName      = "customer-trace-tester"
	TracesGeneratorImage     = "sumologic/kubernetes-tools:2.14.0"

	MultilineLogsNamespace = "multiline-logs-generator"
	MultilineLogsPodName   = "multiline-logs-generator"
	MultilineLogsGenerator = "yamls/multiline-logs-generator.yaml"

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
	KubeletMetrics = []string{
		"kubelet_running_containers",
		"kubelet_running_pods",
	}
	KubeSchedulerMetrics = []string{
		// TODO: check different metrics depending on K8s version
		// scheduler_scheduling_duration_seconds is present for K8s <1.23
		// scheduler_scheduling_attempt_duration_seconds is present for K8s >=1.23
		// "scheduler_e2e_scheduling_duration_seconds_count",
		// "scheduler_e2e_scheduling_duration_seconds_sum",
		// "scheduler_e2e_scheduling_duration_seconds_bucket",
		// "scheduler_scheduling_attempt_duration_seconds_count",
		// "scheduler_scheduling_attempt_duration_seconds_sum",
		// "scheduler_scheduling_attempt_duration_seconds_bucket",
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
		"etcd_disk_wal_fsync_duration_seconds_bucket",
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
	DefaultOtelcolMetrics = []string{
		"otelcol_exporter_enqueue_failed_log_records",
		"otelcol_exporter_enqueue_failed_metric_points",
		"otelcol_exporter_enqueue_failed_spans",
		"otelcol_exporter_queue_capacity",
		"otelcol_process_cpu_seconds",
		"otelcol_process_memory_rss",
		"otelcol_process_runtime_heap_alloc_bytes",
		"otelcol_process_runtime_total_alloc_bytes",
		"otelcol_process_runtime_total_sys_memory_bytes",
		"otelcol_process_uptime",
	}
	TracingOtelcolMetrics = []string{
		"otelcol_loadbalancer_num_backend_updates",
		"otelcol_loadbalancer_num_backends",
		"otelcol_loadbalancer_num_resolutions",
	}
	RecordingRuleMetrics = []string{
		":kube_pod_info_node_count:",
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
		KubeletMetrics,
		KubeSchedulerMetrics,
		KubeApiServerMetrics,
		KubeEtcdMetrics,
		KubeControllerManagerMetrics,
		CoreDNSMetrics,
		CAdvisorMetrics,
		NodeExporterMetrics,
		RecordingRuleMetrics,
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
	for _, metrics := range DefaultExpectedMetricsGroups {
		DefaultExpectedFluentdFluentbitMetrics = append(DefaultExpectedMetrics, metrics...)
	}

	DefaultExpectedMetrics = []string{}
	metricsGroupsWithOtelcol := append(DefaultExpectedMetricsGroups, DefaultOtelcolMetrics)
	for _, metrics := range metricsGroupsWithOtelcol {
		DefaultExpectedMetrics = append(DefaultExpectedMetrics, metrics...)
	}

	log.Printf("Successfully read kind images spec")
	log.Printf("Default kind image: %v", KindImages.Default)
	log.Printf("Supported kind images: %v", KindImages.Supported)
	return nil
}
