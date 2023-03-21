//go:build allversions
// +build allversions

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_FluentBit_Fluentd(t *testing.T) {
	expectedMetrics := internal.DefaultExpectedFluentdFluentbitMetrics

	installChecks := []featureCheck{
		CheckSumologicSecret(13),
		CheckFluentdMetadataLogsInstall,
		CheckFluentdMetadataMetricsInstall,
		CheckFluentdEventsInstall,
		CheckPrometheusInstall,
		CheckFluentBitInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featMetrics := GetMetricsFeature(expectedMetrics, Fluentd)

	featTelegrafMetrics := GetTelegrafMetricsFeature(internal.DefaultExpectedNginxAnnotatedMetrics, Fluentd, true)

	featLogs := GetLogsFeature()

	featEvents := GetEventsFeature()

	testenv.Test(t, featInstall, featMetrics, featTelegrafMetrics, featLogs, featEvents)
}
