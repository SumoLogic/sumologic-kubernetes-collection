//go:build allversions
// +build allversions

package integration

import (
	"testing"
)

func Test_Helm_Instrumentation_Metrics(t *testing.T) {
	installChecks := []featureCheck{
		CheckTracesWithoutGatewayInstall,
	}

	featInstall := GetInstallFeature(installChecks)
	featInstrumentationMetrics := GetInstrumentationMetricsFeature()

	testenv.Test(t, featInstall, featInstrumentationMetrics)
}
