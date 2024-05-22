//go:build allversions
// +build allversions

package integration

import (
	"testing"
)

func Test_Helm_Routing_OT(t *testing.T) {

	installChecks := []featureCheck{
		CheckSumologicSecret(15),
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolLogsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetLogsFeature()
	featAdditionalLogs := GetAdditionalLogsFeature()

	featDeployMock := DeployAdditionalSumologicMock()
	featDeleteMock := DeleteAdditionalSumologicMock()

	testenv.Test(t, featDeployMock, featInstall, featLogs, featAdditionalLogs, featDeleteMock)
}
