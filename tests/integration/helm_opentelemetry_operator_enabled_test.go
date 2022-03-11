package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	otoperatorappsv1 "github.com/open-telemetry/opentelemetry-operator/apis/v1alpha1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/e2e-framework/klient/k8s"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

func Test_Helm_OpenTelemetry_Operator_Enabled(t *testing.T) {
	const (
		tickDuration = time.Second
		waitDuration = time.Minute * 2
	)

	featTraces := features.New("traces").
		// TODO: Rewrite into similar step func as WaitUntilStatefulSetIsReady but for deployments
		Assess("otelcol deployment is ready", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctx))
			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-otelcol", releaseName)
			ds := appsv1.DeploymentList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&ds, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			require.NoError(t,
				wait.For(
					conditions.New(res).
						DeploymentConditionMatch(&ds.Items[0], appsv1.DeploymentAvailable, corev1.ConditionTrue),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).
		// TODO: Rewrite into similar step func as WaitUntilStatefulSetIsReady but for daemonsets
		Assess("otelagent daemonset is ready", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctx))
			nl := corev1.NodeList{}
			if !assert.NoError(t, res.List(ctx, &nl)) {
				return ctx
			}

			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-otelagent", releaseName)
			ds := appsv1.DaemonSetList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&ds, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceMatch(&ds.Items[0], func(object k8s.Object) bool {
							d := object.(*appsv1.DaemonSet)
							return d.Status.NumberUnavailable == 0 &&
								d.Status.NumberReady == int32(len(nl.Items))
						}),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).
		Feature()

	featOpenTelemetryOperator := features.New("opentelemetry-operator").
		// TODO: Rewrite into similar step func as WaitUntilStatefulSetIsReady but for deployments
		Assess("opentelemetry-operator deployment is ready", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctx))
			labelSelector := "app.kubernetes.io/name=opentelemetry-operator"
			ds := appsv1.DeploymentList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&ds, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			require.NoError(t,
				wait.For(
					conditions.New(res).
						DeploymentConditionMatch(&ds.Items[0], appsv1.DeploymentAvailable, corev1.ConditionTrue),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).
		Assess("instrumentation-cr in ot-operator1 namespace is created", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctxopts.WithNamespace(ctx, "ot-operator1")))
			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-opentelemetry-operator-instrumentation", releaseName)
			instrs := otoperatorappsv1.InstrumentationList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&instrs, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).
		Assess("instrumentation-cr in ot-operator2 namespace is created", func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
			res := envConf.Client().Resources(ctxopts.Namespace(ctxopts.WithNamespace(ctx, "ot-operator2")))
			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-ot-operator-instrumentation", releaseName)
			instrs := otoperatorappsv1.InstrumentationList{}

			require.NoError(t,
				wait.For(
					conditions.New(res).
						ResourceListN(&instrs, 1,
							resources.WithLabelSelector(labelSelector),
						),
					wait.WithTimeout(waitDuration),
					wait.WithInterval(tickDuration),
				),
			)
			return ctx
		}).
		Feature()

	testenv.Test(t, featTraces, featOpenTelemetryOperator)
}
