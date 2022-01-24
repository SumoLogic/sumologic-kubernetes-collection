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
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/multilinelogsgenerator"
)

type logsGeneratorImplType uint

const (
	LogsGeneratorDeployment = iota
	LogsGeneratorDaemonSet
)

// Generate logsCount logs using the designated implementation type:
// either deployment or a daemonset.
func GenerateLogs(
	implType logsGeneratorImplType,
	logsCount uint,
	logsGeneratorName string,
	logsGeneratorNamespace string,
	logsGeneratorImage string,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		client := envConf.Client()
		generatorOptions := *logsgenerator.NewDefaultGeneratorOptions()
		generatorOptions.TotalLogs = logsCount

		var namespace corev1.Namespace
		err := client.Resources().Get(ctx, logsGeneratorNamespace, "", &namespace)
		if err != nil {
			// create the namespace
			namespace := corev1.Namespace{ObjectMeta: metav1.ObjectMeta{Name: logsGeneratorNamespace}}
			require.NoError(t, client.Resources().Create(ctx, &namespace))
		}

		switch implType {
		case LogsGeneratorDeployment:
			deployment := logsgenerator.GetLogsGeneratorDeployment(
				logsGeneratorNamespace,
				logsGeneratorName,
				logsGeneratorImage,
				generatorOptions,
			)

			// create the deployment
			err := client.Resources(logsGeneratorNamespace).Create(ctx, &deployment)
			require.NoError(t, err)

		case LogsGeneratorDaemonSet:
			daemonset := logsgenerator.GetLogsGeneratorDaemonSet(
				logsGeneratorNamespace,
				logsGeneratorName,
				logsGeneratorImage,
				generatorOptions,
			)

			// create the daemonset
			err := client.Resources(logsGeneratorNamespace).Create(ctx, &daemonset)
			require.NoError(t, err)

		default:
			t.Fatalf("Unknown log generator deployment model: %v", implType)
		}

		return ctx
	}
}
func GenerateMultilineLogsWithPod(
	logsGeneratorName string,
	logsGeneratorNamespace string,
	singlelineLogsBeginningCount int,
	singlelineLogsEndCount int,
	multilineLogsCount int,
	logloopsCount int,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		client := envConf.Client()

		deployment := multilinelogsgenerator.GetMultilineLogsPod(
			logsGeneratorNamespace,
			logsGeneratorName,
			singlelineLogsBeginningCount,
			singlelineLogsEndCount,
			multilineLogsCount,
			logloopsCount,
		)

		// create the namespace
		namespace := corev1.Namespace{ObjectMeta: metav1.ObjectMeta{Name: logsGeneratorNamespace}}
		require.NoError(t, client.Resources().Create(ctx, &namespace))

		// create the deployment
		client.Resources(logsGeneratorNamespace).Create(ctx, &deployment)

		return ctx
	}
}
