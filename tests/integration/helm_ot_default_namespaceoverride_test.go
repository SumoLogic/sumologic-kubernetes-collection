//go:build onlylatest
// +build onlylatest

package integration

import (
	"context"
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"
)

type ctxKey string

const originalNamespaceKey ctxKey = "originalNamespace"

func Test_Helm_Default_OT_NamespaceOverride(t *testing.T) {

	expectedMetrics := []string{}
	// defaults without otel metrics collector metrics, but with Prometheus metrics
	expectedMetricsGroups := make([][]string, len(internal.DefaultExpectedMetricsGroups))
	copy(expectedMetricsGroups, internal.DefaultExpectedMetricsGroups)
	expectedMetricsGroups = append(expectedMetricsGroups, internal.PrometheusMetrics, internal.DefaultOtelcolMetrics, internal.LogsOtelcolMetrics, internal.TracingOtelcolMetrics)
	for _, metrics := range expectedMetricsGroups {
		expectedMetrics = append(expectedMetrics, metrics...)
	}

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

	featMetrics := GetMetricsFeature(expectedMetrics, Prometheus)

	featLogs := GetAllLogsFeature(stepfuncs.WaitUntilExpectedExactLogsPresent, true)

	featMultilineLogs := GetMultilineLogsFeature()

	featEvents := GetEventsFeature()

	featTraces := GetTracesFeature()

	overrideNamespace := func(ctx context.Context, envConf *envconf.Config, t *testing.T, _ features.Feature) (context.Context, error) {
		if !isNamespaceOverridden(t) {
			return ctx, nil
		}
		originalNamespace := ctxopts.Namespace(ctx)
		ctx = context.WithValue(ctx, originalNamespaceKey, originalNamespace)
		kubectlOptions := ctxopts.KubectlOptions(ctx)
		kubectlOptions.Namespace = internal.OverrideNamespace
		ctx = ctxopts.WithKubectlOptions(ctx, kubectlOptions)
		ctx = ctxopts.WithNamespace(ctx, internal.OverrideNamespace)
		return ctx, nil
	}
	restoreOriginalNamespace := func(ctx context.Context, envConf *envconf.Config, t *testing.T, _ features.Feature) (context.Context, error) {
		if !isNamespaceOverridden(t) {
			return ctx, nil
		}
		originalNamespace := ctx.Value(originalNamespaceKey).(string)
		kubectlOptions := ctxopts.KubectlOptions(ctx)
		kubectlOptions.Namespace = originalNamespace
		ctx = ctxopts.WithKubectlOptions(ctx, kubectlOptions)
		ctx = ctxopts.WithNamespace(ctx, originalNamespace)
		return ctx, nil
	}

	testenv.BeforeEachFeature(overrideNamespace).AfterEachFeature(restoreOriginalNamespace).Test(t, featInstall, featMetrics, featLogs, featMultilineLogs, featEvents, featTraces)
}

func isNamespaceOverridden(t *testing.T) bool {
	valuesFileBytes := stepfuncs.GetHelmValuesForT(t)
	var values struct {
		NamespaceOverride string `yaml:"namespaceOverride"`
	}

	err := yaml.Unmarshal(valuesFileBytes, &values)
	require.NoError(t, err)
	return (values.NamespaceOverride != "")
}
