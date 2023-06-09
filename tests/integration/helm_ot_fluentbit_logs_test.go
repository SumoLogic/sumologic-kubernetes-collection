package integration

import (
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_OT_FluentBit_Logs(t *testing.T) {
	installChecks := []featureCheck{
		CheckSumologicSecret(1),
		CheckOtelcolMetadataLogsInstall,
		CheckFluentBitInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featLogs := GetLogsFeature()

	f := stepfuncs.IntoTestEnvFuncs(
		stepfuncs.KubectlCreateNamespaceOpt(internal.OverrideNamespace),
	)

	testenv.BeforeEachFeature(f).Test(t, featInstall, featLogs)

}
