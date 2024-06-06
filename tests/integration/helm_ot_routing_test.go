//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_Routing_OT(t *testing.T) {

	installChecks := []featureCheck{
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolLogsCollectorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetAllLogsFeature(stepfuncs.WaitUntilExpectedExactLogsPresent, true)
	featAdditionalLogs := GetAllLogsFeature(stepfuncs.WaitUntilExpectedAdditionalLogsPresent, false)

	featDeployMock := DeployAdditionalSumologicMock()
	featDeleteMock := DeleteAdditionalSumologicMock()

	testenv.Test(t, featInstall, featDeployMock, featLogs, featAdditionalLogs, featDeleteMock)
}
