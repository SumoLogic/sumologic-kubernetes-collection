package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"

	corev1 "k8s.io/api/core/v1"
	log "k8s.io/klog/v2"
	"sigs.k8s.io/e2e-framework/klient/k8s"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_Otelcol_Logs(t *testing.T) {
	const (
		tickDuration            = 3 * time.Second
		waitDuration            = 3 * time.Minute
		logsGeneratorCount uint = 1000
		logRecords              = 4   //	number of log records in single loop, see: tests/integration/yamls/pod_multiline_long_lines.yaml
		logLoops                = 500 // number of loops in which logs are generated, see: tests/integration/yamls/pod_multiline_long_lines.yaml
		multilineLogCount  uint = logRecords * logLoops
	)

	featInstall := features.New("installation").
		Assess("sumologic secret is created with endpoints",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				terrak8s.WaitUntilSecretAvailable(t, ctxopts.KubectlOptions(ctx), "sumologic", 60, tickDuration)
				secret := terrak8s.GetSecret(t, ctxopts.KubectlOptions(ctx), "sumologic")
				require.Len(t, secret.Data, 2, "Secret has incorrect number of endpoints. There should be only 1 endpoint, for logs.")
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
					ResourceListMatchN(&pvcs, 3,
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
		Assess("otelcol daemonset is ready",
			stepfuncs.WaitUntilDaemonSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs-collector"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-logs-collector"),
					},
				),
			),
		).
		Feature()
	featLogs := features.New("logs").
		Setup(stepfuncs.GenerateLogs(
			stepfuncs.LogsGeneratorDeployment,
			logsGeneratorCount,
			internal.LogsGeneratorName,
			internal.LogsGeneratorNamespace,
			internal.LogsGeneratorImage,
		)).
		Assess("logs from log generator present", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Assess("expected container log metadata is present", stepfuncs.WaitUntilExpectedLogsPresent(
			logsGeneratorCount,
			map[string]string{
				"_collector":       "kubernetes",
				"cluster":          "kubernetes",
				"namespace":        internal.LogsGeneratorName,
				"pod_labels_app":   internal.LogsGeneratorName,
				"container":        internal.LogsGeneratorName,
				"deployment":       internal.LogsGeneratorName,
				"replicaset":       "",
				"pod":              "",
				"k8s.pod.id":       "",
				"k8s.pod.pod_name": "",
				// "k8s.container.id": "", // TODO: disable this for other tests, it's not reliable
				"host": "",
				"node": "",
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
				"_sourceName":     "",
				"_sourceCategory": "kubernetes/system",
				"_sourceHost":     "",
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
				"_sourceHost":     "",
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
		Teardown(stepfuncs.KubectlDeleteNamespaceOpt(internal.LogsGeneratorNamespace)).
		Feature()

	featMultilineLogs := features.New("multiline logs").
		Setup(stepfuncs.KubectlApplyFOpt(internal.MultilineLogsGenerator, internal.MultilineLogsNamespace)).
		Assess("multiline logs present", stepfuncs.WaitUntilExpectedLogsPresent(
			multilineLogCount,
			map[string]string{
				"namespace":          internal.MultilineLogsNamespace,
				"pod_labels_example": internal.MultilineLogsPodName,
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Teardown(stepfuncs.KubectlDeleteFOpt(internal.MultilineLogsGenerator, internal.MultilineLogsNamespace)).
		Feature()

	testenv.Test(t, featInstall, featLogs, featMultilineLogs)
}
