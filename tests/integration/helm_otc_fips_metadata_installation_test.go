//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_Default_OT_FIPS(t *testing.T) {

	expectedMetrics := internal.DefaultExpectedMetrics
	// we have tracing enabled, so check tracing-specific metrics
	expectedMetrics = append(expectedMetrics, internal.TracingOtelcolMetrics...)

	installChecks := []featureCheck{
		CheckSumologicSecret(15),
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolMetadataMetricsInstall,
		CheckOtelcolEventsInstall,
		CheckOtelcolMetricsCollectorInstall,
		CheckOtelcolLogsCollectorInstall,
		CheckTracesInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featMetrics := GetMetricsFeature(expectedMetrics, Otelcol)

	featTelegrafMetrics := GetTelegrafMetricsFeature(internal.DefaultExpectedNginxAnnotatedMetrics, Otelcol, true)

	featLogs := GetLogsFeature()

	featMultilineLogs := GetMultilineLogsFeature()

	featEvents := GetEventsFeature()

	featTraces := GetTracesFeature()

	testenv.Test(t, featInstall, featMetrics, featTelegrafMetrics, featLogs, featMultilineLogs, featEvents, featTraces)
}
