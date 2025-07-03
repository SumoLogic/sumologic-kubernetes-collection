//go:build allversions
// +build allversions

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_Default_OT(t *testing.T) {

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

	featMetrics := GetMetricsFeature(expectedMetrics, Otelcol, true)

	featTelegrafMetrics := GetTelegrafMetricsFeature(internal.DefaultExpectedNginxAnnotatedMetrics, Otelcol, true)

	featLogs := GetAllLogsFeature(stepfuncs.WaitUntilExpectedExactLogsPresent, true)

	featMultilineLogs := GetMultipleMultilineLogsFeature()

	featEvents := GetEventsFeature()

	featTraces := GetTracesFeature()

	testenv.Test(t, featInstall, featMetrics, featTelegrafMetrics, featLogs, featMultilineLogs, featEvents, featTraces)
}
