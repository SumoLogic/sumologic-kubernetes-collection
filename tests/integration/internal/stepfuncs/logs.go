package stepfuncs

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/logsgenerator"
)

// Generate logsCount logs using a Deployment
func GenerateLogsWithDeployment(
	logsCount uint,
	logsGeneratorName string,
	logsGeneratorNamespace string,
	logsGeneratorImage string,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		client := envConf.Client()
		generatorOptions := *logsgenerator.NewDefaultGeneratorOptions()
		generatorOptions.TotalLogs = logsCount
		deployment := logsgenerator.GetLogsGeneratorDeployment(
			logsGeneratorNamespace,
			logsGeneratorName,
			logsGeneratorImage,
			generatorOptions,
		)

		// create the namespace
		namespace := corev1.Namespace{ObjectMeta: metav1.ObjectMeta{Name: logsGeneratorNamespace}}
		require.NoError(t, client.Resources().Create(ctx, &namespace))

		// create the deployment
		err := client.Resources(logsGeneratorNamespace).Create(ctx, &deployment)
		require.NoError(t, err)

		return ctx
	}
}
