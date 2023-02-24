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
		"scheduler_e2e_scheduling_duration_seconds_count",
		"scheduler_e2e_scheduling_duration_seconds_sum",
		"scheduler_e2e_scheduling_duration_seconds_bucket",
		"scheduler_scheduling_algorithm_duration_seconds_count",
		"scheduler_scheduling_algorithm_duration_seconds_sum",
		"scheduler_scheduling_algorithm_duration_seconds_bucket",
		// Deprecated in Kubernetes 1.21: https://github.com/kubernetes/kubernetes/pull/96447
		// TODO: Remove this and the values.yaml settings after we drop support for 1.20
		// "scheduler_binding_duration_seconds",
	}
	KubeApiServerMetrics = []string{
		"apiserver_request_total",
		"apiserver_request_duration_seconds_count",
		"apiserver_request_duration_seconds_sum",
		// We have the following metrics in our values.yaml, but they've been deprecated for a while
		// Kubernetes 1.14 deprecation notice:
		// https://github.com/kubernetes/kubernetes/blob/8ac5d4d6a92d59bba70844fbd6e5de2383a08c96/CHANGELOG/CHANGELOG-1.14.md#deprecated-metrics
		// Kubernetes 1.17 disablement notice:
		// https://github.com/kubernetes/kubernetes/blob/ea0764452222146c47ec826977f49d7001b0ea8c/CHANGELOG/CHANGELOG-1.17.md#deprecatedchanged-metrics
		// TODO: Remove these from values.yaml and replace them with non-deprecated equivalents
		// "apiserver_request_latencies_count",
		// "apiserver_request_latencies_sum",
		// "apiserver_request_latencies_summary",
		// "apiserver_request_latencies_summary_count",
		// "apiserver_request_latencies_summary_sum",
	}
	KubeEtcdMetrics = []string{
		// Deprecated in etcd v3: https://github.com/kubernetes/kubernetes/pull/79520
		// "etcd_request_cache_get_duration_seconds_count",
		// "etcd_request_cache_get_duration_seconds_sum",
		// "etcd_request_cache_add_duration_seconds_count",
		// "etcd_request_cache_add_duration_seconds_sum",
		// "etcd_request_cache_add_latencies_summary_count",
		// "etcd_request_cache_add_latencies_summary_sum",
		// "etcd_request_cache_get_latencies_summary_count",
		// "etcd_request_cache_get_latencies_summary_sum",
		// "etcd_helper_cache_hit_count",
		// "etcd_helper_cache_hit_total",
		// "etcd_helper_cache_miss_count",
		// "etcd_helper_cache_miss_total",
		// Deprecated in etcd 3.5: https://github.com/etcd-io/etcd/blob/e433d12656c5dbd41f4f6b085ced134647ffeb14/CHANGELOG-3.5.md#breaking-changes
		// TODO: Replace with etcd_mvcc_db_total_size_in_bytes
		//"etcd_debugging_mvcc_db_total_size_in_bytes",
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
		"cloudprovider_aws_api_request_duration_seconds_bucket",
		"cloudprovider_aws_api_request_duration_seconds_count",
		"cloudprovider_aws_api_request_duration_seconds_sum",
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
		// Deprecated in https://coredns.io/2020/06/15/coredns-1.7.0-release/#metric-changes
		// "coredns_cache_size",
		// "coredns_dns_response_rcode_count_total",
		// "coredns_forward_request_count_total",
		// No idea where this came from, doesn't seem to exist
		// TODO: confirm it doesn't exist and remove it from values.yaml
		// "coredns_dns_request_count_total",
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
	OtelcolMetrics = []string{
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
		"otelcol_loadbalancer_num_backend_updates",
		"otelcol_loadbalancer_num_backends",
		"otelcol_loadbalancer_num_resolutions",
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
		// See: https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/2079
		// TODO: Enable this again after the above issue is resolved
		// KubeSchedulerMetrics,
		KubeApiServerMetrics,
		KubeEtcdMetrics,
		// Need to upgrade kube-prometheus stack to use the secure metrics endpoint for controller metrics
		// KubeControllerManagerMetrics,
		CoreDNSMetrics,
		CAdvisorMetrics,
		NodeExporterMetrics,
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

	DefaultExpectedMetrics = []string{}
	metricsGroupsWithOtelcol := append(DefaultExpectedMetricsGroups, OtelcolMetrics)
	for _, metrics := range metricsGroupsWithOtelcol {
		DefaultExpectedMetrics = append(DefaultExpectedMetrics, metrics...)
	}

	DefaultExpectedFluentdFluentbitMetrics = []string{}
	for _, metrics := range DefaultExpectedMetricsGroups {
		DefaultExpectedFluentdFluentbitMetrics = append(DefaultExpectedMetrics, metrics...)
	}

	log.Printf("Successfully read kind images spec")
	log.Printf("Default kind image: %v", KindImages.Default)
	log.Printf("Supported kind images: %v", KindImages.Supported)
	return nil
}
