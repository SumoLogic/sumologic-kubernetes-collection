//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_OTLP(t *testing.T) {

	expectedMetrics := internal.DefaultExpectedMetrics
	// we have tracing enabled, so check tracing-specific metrics
	expectedMetrics = append(expectedMetrics, internal.TracingOtelcolMetrics...)

	installChecks := []featureCheck{
		CheckSumologicSecret(15),
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolMetadataMetricsInstall,
		CheckOtelcolEventsInstall,
		CheckPrometheusInstall,
		CheckOtelcolLogsCollectorInstall,
		CheckTracesInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetLogsFeature()

	featMetrics := GetMetricsFeature(expectedMetrics, Prometheus)

	featTraces := GetTracesFeature()

	featEvents := GetEventsFeature()

	testenv.Test(t, featInstall, featLogs, featMetrics, featEvents, featTraces)
}
