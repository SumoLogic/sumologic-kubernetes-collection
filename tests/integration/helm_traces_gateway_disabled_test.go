//go:build allversions
// +build allversions

package integration

import (
	"testing"
)

func Test_Helm_Traces_Gateway_Disabled(t *testing.T) {

	installChecks := []featureCheck{
		CheckSumologicSecret(3),
		CheckTracesWithoutGatewayInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featTraces := GetTracesFeature()

	testenv.Test(t, featInstall, featTraces)
}
