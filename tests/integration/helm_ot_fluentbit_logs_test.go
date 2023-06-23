//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"
)

func Test_Helm_OT_FluentBit_Logs(t *testing.T) {
	installChecks := []featureCheck{
		CheckSumologicSecret(2),
		CheckOtelcolMetadataLogsInstall,
		CheckFluentBitInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetLogsFeature()

	testenv.Test(t, featInstall, featLogs)
}
