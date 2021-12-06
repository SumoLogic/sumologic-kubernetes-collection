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
	k8sinternal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/k8s"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_Default(t *testing.T) {
	var (
		now            = time.Now()
		namespace      = generateNamespaceName(now)
		releaseName    = generateReleaseName(now)
		valuesFilePath = "values/values_default.yaml"

		tickDuration = time.Second
		waitDuration = time.Minute * 2
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
		Assess("fluentd logs pods are available",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				filters := v1.ListOptions{
					LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-logs", releaseName),
				}
				k8sinternal.WaitUntilPodsAvailable(t, ctxopts.KubectlOptions(ctx), filters, 3, waitDuration*2, tickDuration)
				return ctx
			}).
		Assess("fluentd logs buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				assert.Eventually(t, func() bool {
					var pvcs corev1.PersistentVolumeClaimList
					err := envConf.Client().
						Resources(namespace).
						List(ctx, &pvcs,
							resources.WithLabelSelector(fmt.Sprintf("app=%s-sumologic-fluentd-logs", releaseName)),
						)
					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("fluentd metrics pods are available",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				filters := v1.ListOptions{
					LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-metrics", releaseName),
				}
				k8sinternal.WaitUntilPodsAvailable(t, ctxopts.KubectlOptions(ctx), filters, 3, waitDuration, tickDuration)
				return ctx
			}).
		Assess("fluentd metrics buffers PVCs are created",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				assert.Eventually(t, func() bool {
					var pvcs corev1.PersistentVolumeClaimList
					err := envConf.Client().
						Resources(namespace).
						List(ctx, &pvcs,
							resources.WithLabelSelector(fmt.Sprintf("app=%s-sumologic-fluentd-metrics", releaseName)),
						)
					return err == nil && len(pvcs.Items) == 3
				}, waitDuration, tickDuration)
				return ctx
			}).
		Assess("fluentd events pods are available",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				filters := v1.ListOptions{
					LabelSelector: fmt.Sprintf("app=%s-sumologic-fluentd-events", releaseName),
				}
				k8sinternal.WaitUntilPodsAvailable(t, ctxopts.KubectlOptions(ctx), filters, 1, waitDuration, tickDuration)
				return ctx
			}).
		Assess("fluentd events buffers PVCs are created",
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
		Assess("prometheus pods are available",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				filters := v1.ListOptions{
					LabelSelector: "app=prometheus",
				}
				k8sinternal.WaitUntilPodsAvailable(t, ctxopts.KubectlOptions(ctx), filters, 1, waitDuration, tickDuration)
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
