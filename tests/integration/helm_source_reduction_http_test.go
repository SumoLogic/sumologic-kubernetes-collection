//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"
)

// Test_Helm_Source_Reduction_Http verifies that a fresh install with sourceType=http
// for all signals creates only 11 HTTP sources (no OTLP sources).
func Test_Helm_Source_Reduction_Http(t *testing.T) {
	expectedEndpoints := []string{
		"endpoint-events",
		"endpoint-logs",
		"endpoint-traces",
		"endpoint-metrics",
		"endpoint-metrics-apiserver",
		"endpoint-metrics-kube-controller-manager",
		"endpoint-metrics-kube-scheduler",
		"endpoint-metrics-kube-state",
		"endpoint-metrics-kubelet",
		"endpoint-metrics-node-exporter",
		"endpoint-control_plane_metrics_source",
	}

	installChecks := []featureCheck{
		CheckSumologicSecret(11),
		checkSecretHasOnlyExpectedKeys(expectedEndpoints),
	}

	featInstall := GetInstallFeature(installChecks)
	testenv.Test(t, featInstall)
}
