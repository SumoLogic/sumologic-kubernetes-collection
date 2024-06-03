package stepfuncs

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/tracesgenerator"
)

// Generate logsCount logs using a deployment.
func GenerateTraces(
	tracesPerExporter uint,
	spansPerTrace uint,
	tracesGeneratorName string,
	tracesGeneratorNamespace string,
	tracesGeneratorImage string,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		client := envConf.Client()
		generatorOptions := *tracesgenerator.NewDefaultGeneratorOptions()
		generatorOptions.TracesPerExporter = tracesPerExporter
		generatorOptions.SpansPerTrace = spansPerTrace

		var namespace corev1.Namespace
		err := client.Resources().Get(ctx, tracesGeneratorNamespace, "", &namespace)
		if err != nil {
			// create the namespace
			namespace := corev1.Namespace{ObjectMeta: metav1.ObjectMeta{Name: tracesGeneratorNamespace}}
			require.NoError(t, client.Resources().Create(ctx, &namespace))
		}

		deployment := tracesgenerator.GetTracesGeneratorDeployment(
			ctx,
			t,
			tracesGeneratorNamespace,
			tracesGeneratorName,
			tracesGeneratorImage,
			generatorOptions,
		)

		// create the deployment
		err = client.Resources(tracesGeneratorNamespace).Create(ctx, &deployment)
		require.NoError(t, err)

		return ctx
	}
}
