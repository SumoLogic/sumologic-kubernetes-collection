package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	otoperatorappsv1 "github.com/open-telemetry/opentelemetry-operator/apis/v1alpha1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/client-go/kubernetes/scheme"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_OpenTelemetry_Operator_Enabled(t *testing.T) {
	const (
		tickDuration = time.Second
		waitDuration = time.Minute * 2
	)

	// It is required to add v1alpha1 OT Operator Scheme to K8s Scheme
	// https://github.com/open-telemetry/opentelemetry-operator/issues/772
	if err := otoperatorappsv1.AddToScheme(scheme.Scheme); err != nil {
		require.Fail(t, "failed to register scheme: %v", err)
	}

	featTraces := features.New("traces").
		Assess("traces-sampler deployment is ready",
			stepfuncs.WaitUntilDeploymentIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-traces-sampler"),
				),
				stepfuncs.WithLabelsF(stepfuncs.LabelFormatterKV{
					K: "app",
					V: stepfuncs.ReleaseFormatter("%s-sumologic-traces-sampler"),
				},
				),
			),
		).
		Assess("otelcol-instrumentation statefulset is ready",
			stepfuncs.WaitUntilStatefulSetIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-instrument"),
				),
				stepfuncs.WithLabelsF(
					stepfuncs.LabelFormatterKV{
						K: "app",
						V: stepfuncs.ReleaseFormatter("%s-sumologic-otelcol-instrument"),
					},
				),
			),
		).
		Assess("traces-gateway deployment is ready",
			stepfuncs.WaitUntilDeploymentIsReady(
				waitDuration,
				tickDuration,
				stepfuncs.WithNameF(
					stepfuncs.ReleaseFormatter("%s-sumologic-traces-gateway"),
				),
				stepfuncs.WithLabelsF(stepfuncs.LabelFormatterKV{
					K: "app",
					V: stepfuncs.ReleaseFormatter("%s-sumologic-traces-gateway"),
				},
				),
			),
		).
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
			res := envConf.Client().Resources("ot-operator1")
			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-ot-operator-instr", releaseName)
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
			res := envConf.Client().Resources("ot-operator2")
			releaseName := ctxopts.HelmRelease(ctx)
			labelSelector := fmt.Sprintf("app=%s-sumologic-ot-operator-instr", releaseName)
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
