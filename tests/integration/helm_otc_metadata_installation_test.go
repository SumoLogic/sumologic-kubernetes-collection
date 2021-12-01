package main

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_OT_Metadata(t *testing.T) {
	var (
		now            = time.Now()
		namespace      = generateNamespaceName(now)
		releaseName    = generateReleaseName(now)
		valuesFilePath = "values/values_otc_metadata.yaml"

		tickDuration = time.Second
		waitDuration = time.Minute
	)

	feat := features.New("installation").
		// Setup
		Setup(stepfuncs.SetKubectlNamespaceOpt(namespace)).
		Setup(stepfuncs.KubectlApplyFOpt(internal.YamlPathReceiverMock, "receiver-mock")).
		Setup(stepfuncs.SetHelmOptionsOpt(valuesFilePath)).
		Setup(stepfuncs.HelmDependencyUpdateOpt(internal.HelmSumoLogicChartAbsPath)).
		Setup(stepfuncs.HelmInstallOpt(internal.HelmSumoLogicChartAbsPath, releaseName)).
		// Teardown
		Teardown(stepfuncs.PrintClusterStateOpt()).
		Teardown(stepfuncs.HelmDeleteOpt(releaseName)).
		Teardown(stepfuncs.KubectlDeleteNamespaceOpt(namespace)).
		Teardown(stepfuncs.KubectlDeleteFOpt(internal.YamlPathReceiverMock, "receiver-mock")).
		// Assess
		Assess("sumologic secret is created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				k8s.WaitUntilSecretAvailable(t, ctxopts.KubectlOptions(ctx), "sumologic", 60, tickDuration)
				secret := k8s.GetSecret(t, ctxopts.KubectlOptions(ctx), "sumologic")
				require.Len(t, secret.Data, 10)
				return ctx
			}).
		Assess("3 otelcol logs pods are created, running and ready",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				require.Eventually(t, func() bool {
					pods := k8s.ListPods(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: fmt.Sprintf("app=%s-sumologic-otelcol-logs", releaseName),
						FieldSelector: "status.phase=Running",
					})

					if len(pods) != 3 {
						return false
					}

					for _, pod := range pods {
						for _, container := range pod.Status.ContainerStatuses {
							if !container.Ready {
								return false
							}
						}
					}

					return true
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("3 otelcol logs buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				assert.Eventually(t, func() bool {
					var pvcs corev1.PersistentVolumeClaimList
					err := envConf.Client().
						Resources(namespace).
						List(ctx, &pvcs,
							resources.WithLabelSelector(fmt.Sprintf("app=%s-sumologic-otelcol-logs", releaseName)),
						)

					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("3 otelcol metrics pods are created, running and ready",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				require.Eventually(t, func() bool {
					pods := k8s.ListPods(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: fmt.Sprintf("app=%s-sumologic-otelcol-metrics", releaseName),
						FieldSelector: "status.phase=Running",
					})

					if len(pods) != 3 {
						return false
					}

					for _, pod := range pods {
						for _, container := range pod.Status.ContainerStatuses {
							if !container.Ready {
								return false
							}
						}
					}

					return true
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("3 otelcol metrics buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				assert.Eventually(t, func() bool {
					var pvcs corev1.PersistentVolumeClaimList
					err := envConf.Client().
						Resources(namespace).
						List(ctx, &pvcs,
							resources.WithLabelSelector(fmt.Sprintf("app=%s-sumologic-otelcol-metrics", releaseName)),
						)
					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("1 fluentd events pod is created and running",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				require.Eventually(t, func() bool {
					pods := k8s.ListPods(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-events", releaseName),
						FieldSelector: "status.phase=Running",
					})
					return len(pods) == 1
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("1 fluentd events buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				assert.Eventually(t, func() bool {
					var pvcs corev1.PersistentVolumeClaimList
					err := envConf.Client().
						Resources(namespace).
						List(ctx, &pvcs,
							resources.WithLabelSelector(fmt.Sprintf("app=%s-sumologic-fluentd-events", releaseName)),
						)
					return err == nil && len(pvcs.Items) == 1
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("1 prometheus pod is created and running",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				require.Eventually(t, func() bool {
					pods := k8s.ListPods(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: "app=prometheus",
						FieldSelector: "status.phase=Running",
					})
					return len(pods) == 1
				}, waitDuration, tickDuration)
				return ctx
			}).
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

	testenv.Test(t, feat)
}
