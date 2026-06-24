//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
)

func Test_Helm_Single_Layer_Pipeline(t *testing.T) {
	expectedMetrics := internal.DefaultExpectedMetrics

	installChecks := []featureCheck{
		CheckOtelcolMetricsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)
	featMetrics := GetMetricsFeature(expectedMetrics, Otelcol)

	testenv.Test(t, featInstall, featMetrics)
}
