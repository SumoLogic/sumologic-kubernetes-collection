package integration

import (
	"testing"
)

func Test_Helm_OTLP(t *testing.T) {

	installChecks := []featureCheck{
		CheckSumologicSecret(2),
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolLogsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetLogsFeature()

	testenv.Test(t, featInstall, featLogs)
}
