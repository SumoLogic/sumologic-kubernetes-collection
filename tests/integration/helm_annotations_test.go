//go:build onlylatest
// +build onlylatest

package integration

import (
	"testing"
)

func Test_Helm_Annotations(t *testing.T) {
	installChecks := []featureCheck{
		CheckOtelcolMetadataLogsInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featAnnotationsTest := GetAnnotationsFeature()

	testenv.Test(t, featInstall, featAnnotationsTest)
}
