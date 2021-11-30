package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"testing"
	"time"

	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

func Test_Helm_With_Falco(t *testing.T) {
	var (
		now            = time.Now()
		namespace      = generateNamespaceName(now)
		releaseName    = generateReleaseName(now)
		valuesFilePath = "values/values_with_falco_enabled.yaml"

		tickDuration = time.Second
		waitDuration = 2 * time.Minute
	)

	feat := features.New("falco").
		// Setup
		Setup(stepfuncs.SetKubectlNamespaceOpt(namespace)).
		Setup(stepfuncs.KubectlApplyFOpt(internal.YamlPathReceiverMock, "receiver-mock")).
		Setup(stepfuncs.SetHelmOptionsOpt(valuesFilePath)).
		Setup(stepfuncs.HelmDependencyUpdateOpt(internal.HelmSumoLogicChartAbsPath)).
		Setup(stepfuncs.HelmInstallOpt(internal.HelmSumoLogicChartAbsPath, releaseName)).
		// Teardown
		Teardown(stepfuncs.HelmDeleteOpt(releaseName)).
		Teardown(stepfuncs.KubectlDeleteNamespaceOpt(namespace)).
		Teardown(stepfuncs.KubectlDeleteFOpt(internal.YamlPathReceiverMock, "receiver-mock")).
		Teardown(stepfuncs.PrintClusterStateOpt(true)).
		// Assess
		Assess("falco daemonset is running",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				// var daemonsets []appsv1.DaemonSet
				// require.Eventually(t, func() bool {
				// 	daemonsets = k8s.ListDaemonSets(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
				// 		LabelSelector: "app.kubernetes.io/name=fluent-bit",
				// 	})

				// 	return len(daemonsets) == 1
				// }, waitDuration, tickDuration)

				pods := k8s.ListPods(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
					LabelSelector: fmt.Sprintf("app=%s-falco", releaseName),
					// FieldSelector: "status.phase=Running",
				})
				require.Eventually(t, func() bool {
					pods = k8s.ListPods(t, ctxopts.KubectlOptions(ctx), v1.ListOptions{
						LabelSelector: fmt.Sprintf("app=%s-falco", releaseName),
						// FieldSelector: "status.phase=Running",
					})
					return len(pods) == 1 && pods[0].Status.Phase != "Pending"
				}, waitDuration, tickDuration)

				// k8s.WaitUntilPodAvailable(t, ctxopts.KubectlOptions(ctx), pods[0].Name, 120, tickDuration)

				for i := 0; i < 10; i++ {
					// k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx),
					// 	"logs", fmt.Sprintf("-lapp=%s-falco", releaseName),
					// )
					k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx),
						"logs", "--all-containers=true", fmt.Sprintf("-lapp=%s-falco", releaseName),
					)
					k8s.RunKubectl(t, ctxopts.KubectlOptions(ctx),
						"describe", "pod", fmt.Sprintf("-lapp=%s-falco", releaseName),
					)
					time.Sleep(5 * time.Second)
				}

				// require.EqualValues(t, 0, daemonsets[0].Status.NumberUnavailable)
				return ctx
			}).
		Assess("wait",
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				ch := make(chan os.Signal, 1)
				signal.Notify(ch, os.Interrupt, os.Kill)
				select {
				case <-time.After(time.Hour):
				case <-ch:
				}
				return ctx
			}).
		Feature()

	testenv.Test(t, feat)
}
