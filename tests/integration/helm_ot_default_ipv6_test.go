//go:build onlylatest
// +build onlylatest

package integration

import (
	"strings"
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func FilterOutIPv6ExcludedMetrics(metrics []string) []string {
    ipv6ExcludedMetrics := []string{ //Add metrics that are not relevant for IPv6
        "coredns_cache_hits_total",
    }
    var filtered []string
    for _, m := range metrics {
        exclude := false
        for _, excl := range ipv6ExcludedMetrics {
            if strings.Contains(m, excl) {
                exclude = true
                break
            }
        }
        if !exclude {
            filtered = append(filtered, m)
        }
    }
    return filtered
}

func Test_Helm_Default_OT_ipv6(t *testing.T) {

	expectedMetrics := internal.DefaultExpectedMetrics
	
	expectedMetrics = append(expectedMetrics, internal.TracingOtelcolMetrics...)
	expectedMetrics = FilterOutIPv6ExcludedMetrics(expectedMetrics)

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