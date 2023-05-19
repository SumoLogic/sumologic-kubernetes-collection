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
	// also don't check otelcol metrics for now, we don't have a ServiceMonitor
	expectedMetricsGroups := [][]string{
		internal.KubeStateMetrics,
		internal.KubeDaemonSetMetrics,
		internal.KubeDeploymentMetrics,
		internal.KubeNodeMetrics,
		internal.KubePodMetrics,
		internal.KubeletMetrics,
		internal.KubeSchedulerMetrics,
		internal.KubeApiServerMetrics,
		internal.KubeEtcdMetrics,
		internal.KubeControllerManagerMetrics,
		internal.CoreDNSMetrics,
		internal.CAdvisorMetrics,
		internal.NodeExporterMetrics,
	}
	for _, metrics := range expectedMetricsGroups {
		for _, metric := range metrics {
			if strings.HasSuffix(metric, "_count") ||
				strings.HasSuffix(metric, "_sum") ||
				strings.HasSuffix(metric, "_bucket") {
				continue
			}
			expectedMetrics = append(expectedMetrics, metric)
		}
	}

	installChecks := []featureCheck{
		CheckSumologicSecret(8),
		CheckOtelcolMetricsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featMetrics := GetMetricsFeature(expectedMetrics, Otelcol)

	testenv.Test(t, featInstall, featMetrics)
}
