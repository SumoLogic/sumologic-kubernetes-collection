//go:build allversions
// +build allversions

package integration

import (
	"testing"
)

func Test_Helm_Routing_Partial(t *testing.T) {

	installChecks := []featureCheck{
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolLogsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetPartialLogsFeature()

	featDeployMock := DeployAdditionalSumologicMock()
	featDeleteMock := DeleteAdditionalSumologicMock()

	testenv.Test(t, featInstall, featDeployMock, featLogs, featDeleteMock)
}
