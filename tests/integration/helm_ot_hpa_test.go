//go:build allversions
// +build allversions

package integration

import (
	"testing"

	strings_internal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
)

func Test_Helm_OT_HPA(t *testing.T) {
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

	releaseName := strings_internal.ReleaseNameFromT(t)
	featHPA := GetHPAFeature(releaseName)

	testenv.Test(t, featInstall, featHPA)
}
