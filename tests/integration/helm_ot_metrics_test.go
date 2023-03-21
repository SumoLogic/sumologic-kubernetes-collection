//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_OT_Metrics(t *testing.T) {
	expectedMetrics := []string{}

	// don't check recording rule metrics, not supported
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
			expectedMetrics = append(expectedMetrics, metric)
		}
	}

	installChecks := []featureCheck{
		CheckSumologicSecret(9),
		CheckOtelcolMetadataMetricsInstall,
		CheckOtelcolMetricsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featMetrics := GetMetricsFeature(expectedMetrics, Otelcol)

	featTelegrafMetrics := GetTelegrafMetricsFeature(internal.DefaultExpectedNginxAnnotatedMetrics, Otelcol, true)

	testenv.Test(t, featInstall, featMetrics, featTelegrafMetrics)
}
