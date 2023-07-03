//go:build onlylatest
// +build onlylatest

package integration

import (
	"strings"
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_OT_Metrics(t *testing.T) {
	expectedMetrics := []string{}

	// drop histogram metrics for now, there's a couple problems with them
	// don't check recording rule metrics, not supported yet
	expectedMetricsGroups := [][]string{
		internal.KubeStateMetrics,
		internal.KubeDaemonSetMetrics,
		internal.KubeDeploymentMetrics,
		internal.KubeNodeMetrics,
		internal.AdditionalKubePodMetrics,
		internal.KubePodMetrics,
		internal.KubeServiceMetrics,
		internal.KubeletMetrics,
		internal.KubeSchedulerMetrics,
		internal.KubeApiServerMetrics,
		internal.KubeEtcdMetrics,
		internal.KubeControllerManagerMetrics,
		internal.CoreDNSMetrics,
		internal.CAdvisorMetrics,
		internal.NodeExporterMetrics,
		internal.AdditionalNodeExporterMetrics,
		internal.DefaultOtelcolMetrics,
		internal.MetricsCollectorOtelcolMetrics,
		internal.OtherMetrics,
	}
	for _, metrics := range expectedMetricsGroups {
		for _, metric := range metrics {
			if strings.HasPrefix(metric, "apiserver_request_duration_seconds") ||
				strings.HasPrefix(metric, "coredns_dns_request_duration_seconds") ||
				strings.HasPrefix(metric, "kubelet_runtime_operations_duration_seconds") {
				continue
			}
			expectedMetrics = append(expectedMetrics, metric)
		}
	}

	installChecks := []featureCheck{
		CheckSumologicSecret(8),
		CheckOtelcolMetadataMetricsInstall,
		CheckOtelcolMetricsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featMetrics := GetMetricsFeature(expectedMetrics, Otelcol)

	testenv.Test(t, featInstall, featMetrics)
}
