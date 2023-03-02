package integration

import (
	"testing"
	"time"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
	"sigs.k8s.io/e2e-framework/pkg/features"
)

func Test_Helm_PVC_Cleaner(t *testing.T) {
	const (
		tickDuration = 3 * time.Second
		waitDuration = 5 * time.Minute
	)

	installChecks := []featureCheck{
		CheckOtelcolMetadataLogsInstall,
		CheckOtelcolMetadataMetricsInstall,
	}

	featInstall := GetInstallFeature(installChecks)

	featPvc := features.New("pvc").
		Assess("metrics PVC created for default pod number", stepfuncs.WaitForPvcCount("sumologic-otelcol-metrics", 2, waitDuration, tickDuration)).
		Assess("logs PVC created for default pod number", stepfuncs.WaitForPvcCount("sumologic-otelcol-logs", 2, waitDuration, tickDuration)).
		Assess("metrics statefulset downscaled", stepfuncs.ChangeMinMaxStatefulsetPods("sumologic-otelcol-metrics", 1, 1)).
		Assess("logs statefulset downscaled", stepfuncs.ChangeMinMaxStatefulsetPods("sumologic-otelcol-logs", 1, 1)).
		Assess("metrics unused PVCs removed", stepfuncs.WaitForPvcCount("sumologic-otelcol-metrics", 1, waitDuration, tickDuration)).
		Assess("logs unused PVCs removed", stepfuncs.WaitForPvcCount("sumologic-otelcol-logs", 1, waitDuration, tickDuration)).
		Feature()

	testenv.Test(t, featInstall, featPvc)
}
