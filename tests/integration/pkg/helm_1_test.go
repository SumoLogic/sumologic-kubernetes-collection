package main

import (
	"context"
	"fmt"
	"testing"
	"time"

	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
)

func Test_Helm_DefaultInstallation(t *testing.T) {
	var (
		epoch         = time.Now().Unix()
		namespaceName = fmt.Sprintf("ns-test-%d", epoch)
		releaseName   = fmt.Sprintf("release-test-%d", epoch)
	)

	feat := features.New("helm installation").
		Setup(
			func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
				t.Logf("Kube config: %s", envConf.KubeconfigFile())

				kubectlOptions := k8s.NewKubectlOptions("", envConf.KubeconfigFile(), namespaceName)
				ctx = WithKubectlOptions(ctx, kubectlOptions)

				ctx = WithHelmOptions(ctx, &helm.Options{
					KubectlOptions: kubectlOptions,
					ValuesFiles:    []string{"values/values_default.yaml"},
				})

				k8s.CreateNamespace(t, kubectlOptions, namespaceName)
				return ctx
			}).
		Setup(helmDependencyUpdate(_helmSumoLogicChartRelPath)).
		Setup(helmInstall(HelmSumoLogicChartAbsPath, releaseName)).
		Teardown(
			func(ctx context.Context, t *testing.T, _ *envconf.Config) context.Context {
				helm.Delete(t, HelmOptions(ctx), releaseName, true)
				k8s.DeleteNamespace(t, KubectlOptions(ctx), namespaceName)
				return ctx
			}).
		Feature()

	testenv.Test(t, feat)
}
