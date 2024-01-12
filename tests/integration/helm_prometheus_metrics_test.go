//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_Prometheus_Metrics(t *testing.T) {
	expectedMetrics := []string{}
	// defaults without otel metrics collector metrics, but with Prometheus metrics
	expectedMetricsGroups := make([][]string, len(internal.DefaultExpectedMetricsGroups))
	copy(expectedMetricsGroups, internal.DefaultExpectedMetricsGroups)
	expectedMetricsGroups = append(expectedMetricsGroups, internal.PrometheusMetrics, internal.DefaultOtelcolMetrics, internal.GetVersionDependentMetrics(t))
	for _, metrics := range expectedMetricsGroups {
		expectedMetrics = append(expectedMetrics, metrics...)
	}

	installChecks := []featureCheck{
		CheckSumologicSecret(9),
		CheckOtelcolMetadataMetricsInstall,
		CheckPrometheusInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featMetrics := GetMetricsFeature(expectedMetrics, Prometheus)

	featTelegrafMetrics := GetTelegrafMetricsFeature(internal.DefaultExpectedNginxAnnotatedMetrics, Prometheus, true)

	testenv.Test(t, featInstall, featMetrics, featTelegrafMetrics)
}
