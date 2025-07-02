//go:build onlylatest
// +build onlylatest

package integration

import (
	"strings"
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func FilterOutCoreDNSMetrics(metrics []string) []string {
	var filtered []string
	for _, m := range metrics {
		if !strings.Contains(m, "coredns") {
			filtered = append(filtered, m)
		}
	}
	return filtered
}

func Test_Helm_Default_OT_ipv6(t *testing.T) {

	expectedMetrics := internal.DefaultExpectedMetrics
	// Remove CoreDNS metrics for IPv6 test as core-dns can't resolve any ipv4 domains in ipv6 mode due to limitations, so it won't be generating expected metrics
	expectedMetrics = FilterOutCoreDNSMetrics(expectedMetrics)
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

	featLogs := GetAllLogsFeature(stepfuncs.WaitUntilExpectedExactLogsPresent, true)

	featMultilineLogs := GetMultipleMultilineLogsFeature()

	featEvents := GetEventsFeature()

	featTraces := GetTracesFeature()

	testenv.Test(t, featInstall, featMetrics, featTelegrafMetrics, featLogs, featMultilineLogs, featEvents, featTraces)
}