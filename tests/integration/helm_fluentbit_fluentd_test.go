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
)

func Test_Helm_FluentBit_Fluentd(t *testing.T) {
	const (
		tickDuration            = 3 * time.Second
		waitDuration            = 5 * time.Minute
		logsGeneratorCount uint = 1000
		expectedEventCount uint = 100
	)
	expectedMetrics := internal.DefaultExpectedFluentdFluentbitMetrics

	featInstall := features.New("installation").
		Assess("sumologic secret is created with endpoints",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				k8s.WaitUntilSecretAvailable(t, ctxopts.KubectlOptions(ctx), "sumologic", 60, tickDuration)
				secret := k8s.GetSecret(t, ctxopts.KubectlOptions(ctx), "sumologic")
				require.Len(t, secret.Data, 10, "Secret has incorrect number of endpoints")
				return ctx
			}).
		Assess("fluentd logs statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-logs"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-logs"),
					},
				),
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
		Assess("fluentd metrics statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-metrics"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-metrics"),
					},
				),
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
		Assess("fluentd events statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-events"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-fluentd-events"),
					},
				),
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
					LabelSelector: "app.kubernetes.io/name=prometheus",
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
		Feature()

	featMetrics := GetMetricsFeature(expectedMetrics)

	featLogs := GetLogsFeature()

	featEvents := GetEventsFeature()

	testenv.Test(t, featInstall, featMetrics, featLogs, featEvents)
}
