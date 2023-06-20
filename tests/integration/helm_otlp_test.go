//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"
)

func Test_Helm_OTLP(t *testing.T) {

	installChecks := []featureCheck{
		CheckSumologicSecret(7),
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolLogsCollectorInstall,
		CheckOtelcolEventsInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetLogsFeature()

	featTraces := GetTracesFeature()

	featEvents := GetEventsFeature()

	testenv.Test(t, featInstall, featLogs, featEvents, featTraces)
}
