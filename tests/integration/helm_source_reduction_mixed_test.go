//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"
)

// Test_Helm_Source_Reduction_Mixed verifies that a fresh install with mixed sourceTypes
// creates only the sources matching each signal's configured sourceType.
// Config: logs=http, metrics=otlp, traces=disabled, events=otlp
// Expected: 3 sources (logs HTTP + metrics OTLP + events OTLP, no traces)
func Test_Helm_Source_Reduction_Mixed(t *testing.T) {
	expectedEndpoints := []string{
		"endpoint-logs",
		"endpoint-metrics-otlp",
		"endpoint-events-otlp",
	}

	installChecks := []featureCheck{
		CheckSumologicSecret(3),
		checkSecretHasOnlyExpectedKeys(expectedEndpoints),
	}

	featInstall := GetInstallFeature(installChecks)
	testenv.Test(t, featInstall)
}
