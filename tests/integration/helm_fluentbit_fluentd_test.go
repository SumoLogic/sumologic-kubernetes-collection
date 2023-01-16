package integration

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"testing"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	log "k8s.io/klog/v2"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/receivermock"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_FluentBit_Fluentd(t *testing.T) {
	const (
		tickDuration            = 3 * time.Second
		waitDuration            = 5 * time.Minute
		logsGeneratorCount uint = 1000
		expectedEventCount uint = 100
	)
	expectedMetrics := internal.DefaultExpectedMetrics

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

	featMetrics := features.New("metrics").
		Assess("expected metrics are present",
			stepfuncs.WaitUntilExpectedMetricsPresent(
				expectedMetrics,
				"receiver-mock",
				"receiver-mock",
				internal.ReceiverMockServicePort,
				waitDuration,
				tickDuration,
			),
		).
		Assess("expected labels are present",
			// TODO: refactor into a step func?
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				// Get the receiver mock pod as metrics source
				res := envConf.Client().Resources(internal.ReceiverMockNamespace)
				podList := corev1.PodList{}
				require.NoError(t,
					wait.For(
						conditions.New(res).
							ResourceListN(
								&podList,
								1,
								resources.WithLabelSelector("app=receiver-mock"),
							),
						wait.WithTimeout(waitDuration),
						wait.WithInterval(tickDuration),
					),
				)
				rClient, tunnelCloseFunc := receivermock.NewClientWithK8sTunnel(ctx, t)
				defer tunnelCloseFunc()

				assert.Eventually(t, func() bool {
					filters := receivermock.MetadataFilters{
						"__name__": "container_memory_working_set_bytes",
						"pod":      podList.Items[0].Name,
					}
					metricsSamples, err := rClient.GetMetricsSamples(filters)
					if err != nil {
						log.ErrorS(err, "failed getting samples from receiver-mock")
						return false
					}

					if len(metricsSamples) == 0 {
						log.InfoS("got 0 metrics samples", "filters", filters)
						return false
					}

					sort.Sort(receivermock.MetricsSamplesByTime(metricsSamples))
					// For now let's take the newest metric sample only because it will have the most
					// accurate labels and the most labels attached (for instance service/deployment
					// labels might not be attached at the very first record).
					sample := metricsSamples[0]
					labels := sample.Labels
					expectedLabels := receivermock.Labels{
						"_origin":   "kubernetes",
						"cluster":   "kubernetes",
						"container": "receiver-mock",
						// TODO: figure out why is this flaky and sometimes it's not there
						// https://github.com/SumoLogic/sumologic-kubernetes-collection/runs/4508796836?check_suite_focus=true
						// "deployment":                   "receiver-mock",
						"endpoint":                     "https-metrics",
						"image":                        "",
						"instance":                     "",
						"job":                          "kubelet",
						"metrics_path":                 "/metrics/cadvisor",
						"namespace":                    "receiver-mock",
						"node":                         "",
						"pod_labels_app":               "receiver-mock",
						"pod_labels_pod-template-hash": "",
						"pod_labels_service":           "receiver-mock",
						"pod":                          podList.Items[0].Name,
						"prometheus_replica":           "",
						"prometheus_service":           "",
						"prometheus":                   "",
						// TODO: figure out why is this flaky and sometimes it's not there
						// https://github.com/SumoLogic/sumologic-kubernetes-collection/runs/4508796836?check_suite_focus=true
						// "replicaset":                   "",
						"service": "receiver-mock",
					}

					log.V(0).InfoS("sample's labels", "labels", labels)

					return labels.MatchAll(expectedLabels)
				}, waitDuration, tickDuration)
				return ctx
			},
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
				"cluster":        internal.ClusterName,
				"namespace":      internal.LogsGeneratorName,
				"pod_labels_app": internal.LogsGeneratorName,
				"container":      internal.LogsGeneratorName,
				"deployment":     internal.LogsGeneratorName,
				"replicaset":     fmt.Sprintf("%s%s", internal.LogsGeneratorName, "-[a-z0-9]{9,10}"),
				"namespace_id":   ".+",
				"pod":            fmt.Sprintf("%s%s", internal.LogsGeneratorName, internal.PodDeploymentSuffixRegex),
				"pod_id":         ".+",
				"container_id":   ".+",
				"host":           internal.NodeNameRegex,
				"master_url":     ".+",
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
					strings.ReplaceAll(internal.LogsGeneratorName, "-", "/"), // this is the pod name prefix, in this case the Deployment name
				),
				"_sourceHost": internal.EmptyRegex,
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
				"_sourceName":     internal.NotUndefinedRegex,
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
				k8s.RunKubectl(t, &opts, "delete", "deployment", internal.LogsGeneratorName)
				return ctx
			}).
		Teardown(stepfuncs.KubectlDeleteNamespaceOpt(internal.LogsGeneratorNamespace)).
		Feature()

	featEvents := features.New("events").
		Assess("events present", stepfuncs.WaitUntilExpectedLogsPresent(
			expectedEventCount,
			map[string]string{
				"_sourceName":     "events",
				"_sourceCategory": fmt.Sprintf("%s/events", internal.ClusterName),
				"cluster":         "kubernetes",
			},
			internal.ReceiverMockNamespace,
			internal.ReceiverMockServiceName,
			internal.ReceiverMockServicePort,
			waitDuration,
			tickDuration,
		)).
		Feature()

	testenv.Test(t, featInstall, featMetrics, featLogs, featEvents)
}
