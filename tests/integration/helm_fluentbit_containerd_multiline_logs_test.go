package integration

import (
	"testing"
)

func Test_Helm_FluentBit_Containerd_Multiline_Logs(t *testing.T) {
	installChecks := []featureCheck{
		CheckSumologicSecret(1),
		CheckOtelcolMetadataLogsInstall,
		CheckFluentBitInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featMultilineLogs := GetMultilineLogsFeature()

	testenv.Test(t, featInstall, featMultilineLogs)
}
