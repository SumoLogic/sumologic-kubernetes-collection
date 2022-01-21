package internal

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"path/filepath"
)

const (
	_helmSumoLogicChartRelPath = "../../deploy/helm/sumologic/"
	_kindImagesJSONPath        = "kind_images.json"

	EnvNameKindImage = "KIND_NODE_IMAGE"

	YamlPathReceiverMock = "yamls/receiver-mock.yaml"

	ReceiverMockServicePort = 3000
	ReceiverMockServiceName = "receiver-mock"
	ReceiverMockNamespace   = "receiver-mock"

	LogsGeneratorNamespace = "logs-generator"
	LogsGeneratorName      = "logs-generator"
	LogsGeneratorImage     = "sumologic/kubernetes-tools:2.9.0"
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
		"kube_pod_container_status_terminated_reason",
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
		CAdvisorMetrics,
		NodeExporterMetrics,
	}
	DefaultExpectedMetrics []string
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

	b, err := ioutil.ReadFile(_kindImagesJSONPath)
	if err != nil {
		return err
	}
	if err = json.Unmarshal(b, &KindImages); err != nil {
		return err
	}

	DefaultExpectedMetrics = []string{}
	for _, metrics := range DefaultExpectedMetricsGroups {
		DefaultExpectedMetrics = append(DefaultExpectedMetrics, metrics...)
	}

	log.Printf("Successfully read kind images spec")
	log.Printf("Default kind image: %v", KindImages.Default)
	log.Printf("Supported kind images: %v", KindImages.Supported)
	return nil
}
