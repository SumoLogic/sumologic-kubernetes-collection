//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"
)

func Test_Helm_Tailing_Sidecar(t *testing.T) {
	installChecks := []featureCheck{
		CheckOtelcolMetadataLogsInstall,
		CheckTailingSidecarOperatorInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featTailingSidecarTest := GetTailingSidecarFeature()

	testenv.Test(t, featInstall, featTailingSidecarTest)
}
