package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
)

func Test_Helm_Default_FluentD_Metadata(t *testing.T) {
	const (
		tickDuration = time.Second
		waitDuration = time.Minute * 2
	)
	var (
		expectedMetrics = internal.DefaultExpectedMetrics
	)

	// TODO:
	// Refactor this: we should find a way to inject this into step func helpers
	// like stepfuncs.WaitUntilPodsAvailable() instead of relying on an implementation
	// detail.
	releaseName := strings.ReleaseNameFromT(t)

	feat := features.New("installation").
		Assess("sumologic secret is created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				k8s.WaitUntilSecretAvailable(t, ctxopts.KubectlOptions(ctx), "sumologic", 60, tickDuration)
				secret := k8s.GetSecret(t, ctxopts.KubectlOptions(ctx), "sumologic")
				require.Len(t, secret.Data, 10)
				return ctx
			}).
		Assess("fluentd logs pods are available",
			stepfuncs.WaitUntilPodsAvailable(
				v1.ListOptions{
					LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-logs", releaseName),
				},
				3,
				waitDuration,
				tickDuration,
			),
		).
		Assess("fluentd logs buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				namespace := ctxopts.Namespace(ctx)
				releaseName := ctxopts.HelmRelease(ctx)
				kubectlOptions := ctxopts.KubectlOptions(ctx)

				t.Logf("kubeconfig: %s", kubectlOptions.ConfigPath)
				cl, err := k8s.GetKubernetesClientFromOptionsE(t, kubectlOptions)
				require.NoError(t, err)

				assert.Eventually(t, func() bool {
					pvcs, err := cl.CoreV1().PersistentVolumeClaims(namespace).
						List(ctx, v1.ListOptions{
							LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-logs", releaseName),
						})
					if !assert.NoError(t, err) {
						return false
					}

					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("fluentd metrics pods are available",
			stepfuncs.WaitUntilPodsAvailable(
				v1.ListOptions{
					LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-metrics", releaseName),
				},
				3,
				waitDuration,
				tickDuration,
			),
		).
		Assess("fluentd metrics buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				namespace := ctxopts.Namespace(ctx)
				releaseName := ctxopts.HelmRelease(ctx)
				kubectlOptions := ctxopts.KubectlOptions(ctx)

				t.Logf("kubeconfig: %s", kubectlOptions.ConfigPath)
				cl, err := k8s.GetKubernetesClientFromOptionsE(t, kubectlOptions)
				require.NoError(t, err)

				assert.Eventually(t, func() bool {
					pvcs, err := cl.CoreV1().PersistentVolumeClaims(namespace).
						List(ctx, v1.ListOptions{
							LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-metrics", releaseName),
						})
					if !assert.NoError(t, err) {
						return false
					}

					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("fluentd events pods are available",
			stepfuncs.WaitUntilPodsAvailable(
				v1.ListOptions{
					LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-events", releaseName),
				},
				1,
				waitDuration,
				tickDuration,
			),
		).
		Assess("fluentd events buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				namespace := ctxopts.Namespace(ctx)
				releaseName := ctxopts.HelmRelease(ctx)
				kubectlOptions := ctxopts.KubectlOptions(ctx)

				t.Logf("kubeconfig: %s", kubectlOptions.ConfigPath)
				cl, err := k8s.GetKubernetesClientFromOptionsE(t, kubectlOptions)
				require.NoError(t, err)

				assert.Eventually(t, func() bool {
					pvcs, err := cl.CoreV1().PersistentVolumeClaims(namespace).
						List(ctx, v1.ListOptions{
							LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-events", releaseName),
						})
					if !assert.NoError(t, err) {
						return false
					}

					return err == nil && len(pvcs.Items) == 1
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("prometheus pods are available",
			stepfuncs.WaitUntilPodsAvailable(
				v1.ListOptions{
					LabelSelector: "app=prometheus",
				},
				1,
				waitDuration,
				tickDuration,
			),
		).
		Assess("fluent-bit daemonset is running",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				var daemonsets []appsv1.DaemonSet
				require.Eventually(t, func() bool {
					daemonsets = k8s.ListDaemonSets(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: "app.kubernetes.io/name=fluent-bit",
					})

					return len(daemonsets) == 1
				}, waitDuration, tickDuration)

				require.EqualValues(t, 0, daemonsets[0].Status.NumberUnavailable)
				return ctx
						}).
		Assess("metrics are present", // TODO: extract this out to a separate feature
			stepfuncs.WaitUntilExpectedMetricsPresent(
				expectedMetrics,
				"receiver-mock",
				"receiver-mock",
				internal.ReceiverMockServicePort,
				waitDuration,
				tickDuration,
			),
		).
		Feature()

	testenv.Test(t, feat)
}
