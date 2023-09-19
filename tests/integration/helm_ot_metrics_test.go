//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_OT_Metrics(t *testing.T) {
	expectedMetrics := internal.DefaultExpectedMetrics

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
