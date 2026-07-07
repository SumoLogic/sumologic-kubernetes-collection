//go:build onlylatest
// +build onlylatest

package integration

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

// Test_Helm_Source_Reduction_Otlp verifies that a fresh install with sourceType=otlp
// for all signals creates only 4 OTLP sources.
func Test_Helm_Source_Reduction_Otlp(t *testing.T) {
	expectedEndpoints := []string{
		"endpoint-events-otlp",
		"endpoint-logs-otlp",
		"endpoint-metrics-otlp",
		"endpoint-traces-otlp",
	}

	installChecks := []featureCheck{
		CheckSumologicSecret(4),
		checkSecretHasOnlyExpectedKeys(expectedEndpoints),
	}

	featInstall := GetInstallFeature(installChecks)
	testenv.Test(t, featInstall)
}

func checkSecretHasOnlyExpectedKeys(expectedKeys []string) featureCheck {
	return func(builder *features.FeatureBuilder) *features.FeatureBuilder {
		return builder.Assess("sumologic secret has only expected source endpoints",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				secret := terrak8s.GetSecretContext(t, ctx, ctxopts.KubectlOptions(ctx, envConf), "sumologic")
				actualKeys := make([]string, 0, len(secret.Data))
				for k := range secret.Data {
					actualKeys = append(actualKeys, k)
				}
				assert.ElementsMatch(t, expectedKeys, actualKeys,
					"Secret should contain only sources matching the configured sourceType")
				require.Len(t, secret.Data, len(expectedKeys))
				return ctx
			})
	}
}
