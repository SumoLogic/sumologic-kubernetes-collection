package stepfuncs

import (
	"context"
	"fmt"
	"testing"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	log "k8s.io/klog/v2"
	"sigs.k8s.io/e2e-framework/klient/k8s"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	terrak8s "github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	k8s_internal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/k8s"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/receivermock"
)

// WaitUntilPodsAvailable returns a features.Func that can be used in `Assess` calls.
// It will wait until the selected pods are available, using the provided total
// `wait` and `tick` times as well as the provided list options and the desired count.
func WaitUntilPodsAvailable(listOptions metav1.ListOptions, count int, wait time.Duration, tick time.Duration) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		k8s_internal.WaitUntilPodsAvailable(t, ctxopts.KubectlOptions(ctx),
			listOptions, count, wait, tick,
		)
		return ctx
	}
}

// WaitUntilExpectedMetricsPresent returns a features.Func that can be used in `Assess` calls.
// It will wait until all the provided metrics are returned by receiver-mock's HTTP API on
// the provided Service and port, until it succeeds or waitDuration passes.
func WaitUntilExpectedMetricsPresent(
	expectedMetrics []string,
	receiverMockNamespace string,
	receiverMockServiceName string,
	receiverMockServicePort int,
	waitDuration time.Duration,
	tickDuration time.Duration,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOpts := *ctxopts.KubectlOptions(ctx)
		kubectlOpts.Namespace = receiverMockNamespace
		terrak8s.WaitUntilServiceAvailable(t, &kubectlOpts, receiverMockServiceName, int(waitDuration), tickDuration)

		client, closeTunnelFunc := receivermock.NewClientWithK8sTunnel(ctx, t)
		defer closeTunnelFunc()

		retries := int(waitDuration / tickDuration)
		message, err := retry.DoWithRetryE(
			t,
			"WaitUntilExpectedMetricsPresent()",
			retries,
			tickDuration,
			func() (string, error) {
				metricCounts, err := client.GetMetricCounts(t)
				if err != nil {
					return "", err
				}
				for _, expectedMetricName := range expectedMetrics {
					_, ok := metricCounts[expectedMetricName]
					if !ok {
						return "", fmt.Errorf("couldn't find metric %q in received metrics", expectedMetricName)
					}
				}
				return fmt.Sprintf("All expected metrics were received: %v", expectedMetrics), nil
			},
		)
		if err != nil {
			t.Fatal(err)
		}
		t.Log(message)
		return ctx
	}
}

// WaitUntilExpectedMetricsPresent returns a features.Func that can be used in `Assess` calls.
// It will wait until the provided number of logs with the provided labels are returned by receiver-mock's HTTP API on
// the provided Service and port, until it succeeds or waitDuration passes.
func WaitUntilExpectedLogsPresent(
	expectedLogsCount uint,
	expectedLogsMetadata map[string]string,
	receiverMockNamespace string,
	receiverMockServiceName string,
	receiverMockServicePort int,
	waitDuration time.Duration,
	tickDuration time.Duration,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		kubectlOpts := *ctxopts.KubectlOptions(ctx)
		kubectlOpts.Namespace = receiverMockNamespace
		terrak8s.WaitUntilServiceAvailable(t, &kubectlOpts, receiverMockServiceName, int(waitDuration), tickDuration)

		client, closeTunnelFunc := receivermock.NewClientWithK8sTunnel(ctx, t)
		defer closeTunnelFunc()

		assert.Eventually(t, func() bool {
			logsCount, err := client.GetLogsCount(t, expectedLogsMetadata)
			if err != nil {
				log.ErrorS(err, "failed getting log counts from receiver-mock")
				return false
			}
			if logsCount < expectedLogsCount {
				log.InfoS(
					"received logs, less than expected",
					"received", logsCount,
					"expected", expectedLogsCount,
				)
				return false
			}
			log.InfoS(
				"received enough logs",
				"received", logsCount,
				"expected", expectedLogsCount,
				"metadata", expectedLogsMetadata,
			)
			return true
		}, waitDuration, tickDuration)
		return ctx
	}
}

// WaitUntilStatefulSetIsReady waits for a specified duration and check with the
// specified tick interval whether the stateful set (as described by the provided options)
// is ready.
//
// Readiness for a stateful set in here is defined as having N ready replicas where
// N is also equal to the spec replicas set on the stateful set.
func WaitUntilStatefulSetIsReady(
	waitDuration time.Duration,
	tickDuration time.Duration,
	opts ...Option,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		sts := appsv1.StatefulSet{
			ObjectMeta: v1.ObjectMeta{
				Namespace: ctxopts.Namespace(ctx),
			},
		}

		listOpts := []resources.ListOption{}
		for _, opt := range opts {
			opt.Apply(ctx, &sts)
			listOpts = append(listOpts, opt.GetListOption(ctx))
		}

		res := envConf.Client().Resources(ctxopts.Namespace(ctx))
		cond := conditions.
			New(res).
			ResourceListMatchN(&appsv1.StatefulSetList{Items: []appsv1.StatefulSet{sts}},
				1,
				func(obj k8s.Object) bool {
					sts := obj.(*appsv1.StatefulSet)
					log.V(5).InfoS("StatefulSet", "status", sts.Status)
					if *sts.Spec.Replicas != sts.Status.ReadyReplicas {
						log.V(0).Infof("StatefulSet %q not yet fully ready", sts.Name)
						return false
					}
					return true
				},
				listOpts...,
			)

		require.NoError(t,
			wait.For(cond,
				wait.WithTimeout(waitDuration),
				wait.WithInterval(tickDuration),
			),
		)

		return ctx
	}
}

// WaitUntilDaemonSetIsReady waits for a specified duration and checks with the
// specified tick interval whether the daemonset (as described by the provided options)
// is ready.
//
// Readiness for a daemonset is defined as having Status.NumberUnavailable == 0.
func WaitUntilDaemonSetIsReady(
	waitDuration time.Duration,
	tickDuration time.Duration,
	opts ...Option,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		ds := appsv1.DaemonSet{
			ObjectMeta: v1.ObjectMeta{
				Namespace: ctxopts.Namespace(ctx),
			},
		}

		listOpts := []resources.ListOption{}
		for _, opt := range opts {
			opt.Apply(ctx, &ds)
			listOpts = append(listOpts, opt.GetListOption(ctx))
		}

		res := envConf.Client().Resources(ctxopts.Namespace(ctx))
		cond := conditions.
			New(res).
			ResourceListMatchN(&appsv1.DaemonSetList{Items: []appsv1.DaemonSet{ds}},
				1,
				func(obj k8s.Object) bool {
					ds := obj.(*appsv1.DaemonSet)
					log.V(5).InfoS("DaemonSet", "status", ds.Status)
					if ds.Status.NumberUnavailable != 0 {
						log.V(0).Infof("DaemonSet %q not yet fully ready", ds.Name)
						return false
					}
					return true
				},
				listOpts...,
			)

		require.NoError(t,
			wait.For(cond,
				wait.WithTimeout(waitDuration),
				wait.WithInterval(tickDuration),
			),
		)

		return ctx
	}
}
