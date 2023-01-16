package integration

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	log "k8s.io/klog/v2"
	"sigs.k8s.io/e2e-framework/klient/k8s"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_OT_FluentBit_Logs(t *testing.T) {
	const (
		tickDuration            = 3 * time.Second
		waitDuration            = 5 * time.Minute
		logsGeneratorCount uint = 1000
	)

	featInstall := features.New("installation").
		Assess("sumologic secret is created with endpoints",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				terrak8s.WaitUntilSecretAvailable(t, ctxopts.KubectlOptions(ctx), "sumologic", 60, tickDuration)
				secret := terrak8s.GetSecret(t, ctxopts.KubectlOptions(ctx), "sumologic")
				require.Len(t, secret.Data, 1, "Secret has incorrect number of endpoints")
				return ctx
			}).
		Assess("otelcol logs statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs"),
					},
				),
			),
		).
		Assess("otelcol logs buffers PVCs are created and bound",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				res := envConf.Client().Resources(ctxopts.Namespace(ctx))
				pvcs := corev1.PersistentVolumeClaimList{}
				cond := conditions.
					New(res).
					ResourceListMatchN(&pvcs, 1,
						func(object k8s.Object) bool {
							pvc := object.(*corev1.PersistentVolumeClaim)
							if pvc.Status.Phase != corev1.ClaimBound {
								log.V(0).Infof("PVC %q not bound yet", pvc.Name)
								return false
							}
							return true
						},
						resources.WithLabelSelector(
							fmt.Sprintf("app=%s-sumologic-otelcol-logs", ctxopts.HelmRelease(ctx)),
						),
					)
				require.NoError(t,
					wait.For(cond,
						wait.WithTimeout(waitDuration),
						wait.WithInterval(tickDuration),
					),
				)
				return ctx
			}).
		Assess("fluent-bit daemonset is running",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				var daemonsets []appsv1.DaemonSet
				require.Eventually(t, func() bool {
					daemonsets = terrak8s.ListDaemonSets(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: "app.kubernetes.io/name=fluent-bit",
					})

					return len(daemonsets) == 1
				}, waitDuration, tickDuration)

				require.EqualValues(t, 0, daemonsets[0].Status.NumberUnavailable)
				return ctx
			}).
		Feature()

	featLogs := features.New("logs").
		Setup(stepfuncs.GenerateLogs(
			stepfuncs.LogsGeneratorDeployment,
			logsGeneratorCount,
			internal.LogsGeneratorName,
			internal.LogsGeneratorNamespace,
			internal.LogsGeneratorImage,
		)).
		Setup(stepfuncs.GenerateLogs(
			stepfuncs.LogsGeneratorDaemonSet,
			logsGeneratorCount,
			internal.LogsGeneratorName,
			internal.LogsGeneratorNamespace,
			internal.LogsGeneratorImage,
		)).
		Assess("logs from log generator deployment present", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"deployment":     internal.LogsGeneratorName,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("logs from log generator daemonset present", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"daemonset":      internal.LogsGeneratorName,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("expected container log metadata is present for log generator deployment", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"cluster":        internal.ClusterName,
				"_collector":     internal.ClusterName,
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"container":      internal.LogsGeneratorName,
				"deployment":     internal.LogsGeneratorName,
				"pod":            fmt.Sprintf("%s%s", internal.LogsGeneratorName, internal.PodDeploymentSuffixRegex),
				"host":           internal.NodeNameRegex,
				"node":           internal.NodeNameRegex,
				"_sourceName": fmt.Sprintf(
					"%s\\.%s%s\\.%s",
					internal.LogsGeneratorNamespace,
					internal.LogsGeneratorName,
					internal.PodDeploymentSuffixRegex,
					internal.LogsGeneratorName,
				),
				"_sourceCategory": fmt.Sprintf(
					"%s/%s/%s", // dashes instead of hyphens due to sourceCategoryReplaceDash
					internal.ClusterName,
					strings.ReplaceAll(internal.LogsGeneratorNamespace, "-", "/"),
					strings.ReplaceAll(internal.LogsGeneratorName, "-", "/"), // this is the pod name prefix, in this case the deployment name
				),
				"_sourceHost": fmt.Sprintf("%s%s", internal.LogsGeneratorName, internal.PodDeploymentSuffixRegex),
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("expected container log metadata is present for log generator daemonset", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"_collector":     "kubernetes",
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"container":      internal.LogsGeneratorName,
				"daemonset":      internal.LogsGeneratorName,
				"pod":            fmt.Sprintf("%s%s", internal.LogsGeneratorName, internal.PodDaemonSetSuffixRegex),
				"host":           internal.NodeNameRegex,
				"node":           internal.NodeNameRegex,
				"_sourceName": fmt.Sprintf(
					"%s\\.%s%s\\.%s",
					internal.LogsGeneratorNamespace,
					internal.LogsGeneratorName,
					internal.PodDaemonSetSuffixRegex,
					internal.LogsGeneratorName,
				),
				"_sourceCategory": fmt.Sprintf(
					"%s/%s/%s", // dashes instead of hyphens due to sourceCategoryReplaceDash
					internal.ClusterName,
					strings.ReplaceAll(internal.LogsGeneratorNamespace, "-", "/"),
					strings.ReplaceAll(internal.LogsGeneratorName, "-", "/"), // this is the pod name prefix, in this case the DaemonSet name
				),
				"_sourceHost": fmt.Sprintf("%s%s", internal.LogsGeneratorName, internal.PodDaemonSetSuffixRegex),
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("logs from node systemd present", stepfuncs.WaitUntilExpectedLogsPresent(
			10, // we don't really control this, just want to check if the logs show up
			map[string]string{
				"cluster":         "kubernetes",
				"_sourceName":     "(?!undefined$).*",
				"_sourceCategory": "kubernetes/system",
				"_sourceHost":     internal.NodeNameRegex,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("logs from kubelet present", stepfuncs.WaitUntilExpectedLogsPresent(
			1, // we don't really control this, just want to check if the logs show up
			map[string]string{
				"cluster":         "kubernetes",
				"_sourceName":     "k8s_kubelet",
				"_sourceCategory": "kubernetes/kubelet",
				"_sourceHost":     internal.NodeNameRegex,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Teardown(
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				opts := *ctxopts.KubectlOptions(ctx)
				opts.Namespace = internal.LogsGeneratorNamespace
				terrak8s.RunKubectl(t, &opts, "delete", "deployment", internal.LogsGeneratorName)
				return ctx
			}).
		Teardown(
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				opts := *ctxopts.KubectlOptions(ctx)
				opts.Namespace = internal.LogsGeneratorNamespace
				terrak8s.RunKubectl(t, &opts, "delete", "daemonset", internal.LogsGeneratorName)
				return ctx
			}).
		Teardown(stepfuncs.KubectlDeleteNamespaceOpt(internal.LogsGeneratorNamespace)).
		Feature()

	testenv.Test(t, featInstall, featLogs)
}
