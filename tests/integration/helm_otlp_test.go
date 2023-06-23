//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"
)

func Test_Helm_OTLP(t *testing.T) {

	installChecks := []featureCheck{
		CheckSumologicSecret(5),
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolLogsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetLogsFeature()

	featTraces := GetTracesFeature()

	testenv.Test(t, featInstall, featLogs, featTraces)
}
