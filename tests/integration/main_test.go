package integration

import (
	"context"
	"fmt"
	"log"
	"os"
	"testing"
	"time"

	"sigs.k8s.io/e2e-framework/klient"
	"sigs.k8s.io/e2e-framework/pkg/env"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/support/kind"

	"github.com/gruntwork-io/terratest/modules/k8s"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
)

const (
	envNameUseKubeConfig = "USE_KUBECONFIG"
	envNameKubeConfig    = "KUBECONFIG"
)

var testenv env.Environment

func TestMain(m *testing.M) {
	if err := internal.InitializeConstants(); err != nil {
		log.Fatalf("failed initializing constants: %v", err)
	}

	cfg, err := envconf.NewFromFlags()
	if err != nil {
		log.Fatalf("envconf.NewFromFlags() failed: %s", err)
	}

	if useKubeConfig := os.Getenv(envNameUseKubeConfig); len(useKubeConfig) > 0 {
		kubeconfig := os.Getenv(envNameKubeConfig)

		cfg.WithKubeconfigFile(kubeconfig)
		testenv = env.NewWithConfig(cfg).
			BeforeEachTest(InjectKubectlOptionsFromKubeconfig(kubeconfig))

		ConfigureTestEnv(testenv)
	} else {
		testenv = env.NewWithConfig(cfg)

		testenv.BeforeEachTest(CreateKindCluster())
		ConfigureTestEnv(testenv)
		testenv.AfterEachTest(DestroyKindCluster())
	}

	os.Exit(testenv.Run(m))
}

func ConfigureTestEnv(testenv env.Environment) {
	const receiverMockNamespace = "receiver-mock"

	// Before
	for _, f := range stepfuncs.IntoTestEnvFuncs(
		stepfuncs.KubectlApplyFOpt(internal.YamlPathReceiverMock, receiverMockNamespace),
		// Needed for OpenTelemetry Operator test
		stepfuncs.KubectlCreateNamespaceOpt("ot-operator1"),
		stepfuncs.KubectlCreateNamespaceOpt("ot-operator2"),
		// Create Test Namespace
		stepfuncs.KubectlCreateNamespaceTestOpt(),
		// SetHelmOptionsTestOpt picks a values file from `values` directory
		// based on the test name ( the details of name generation can be found
		// in `strings.ValueFileFromT()`.)
		// This values file will be used throughout the test to install the
		// collection's chart.
		//
		// The reason for this is to limit the amount of boilerplate in tests
		// themselves but we cannot attach/map the values.yaml to the test itself
		// so we do this mapping instead.
		stepfuncs.SetHelmOptionsTestOpt(),
		stepfuncs.HelmDependencyUpdateOpt(internal.HelmSumoLogicChartAbsPath),
		stepfuncs.HelmInstallTestOpt(internal.HelmSumoLogicChartAbsPath),
	) {
		testenv.BeforeEachTest(f)
	}

	// After
	for _, f := range stepfuncs.IntoTestEnvFuncs(
		stepfuncs.PrintClusterStateOpt(),
		stepfuncs.HelmDeleteTestOpt(),
		stepfuncs.KubectlDeleteNamespaceTestOpt(),
		stepfuncs.KubectlDeleteFOpt(internal.YamlPathReceiverMock, receiverMockNamespace),
	) {
		testenv.AfterEachTest(f)
	}
}

// InjectKubectlOptionsFromKubeconfig injects kubectl options to the context that will be propagated in tests.
// This makes the kubectl options readily available for each test.
func InjectKubectlOptionsFromKubeconfig(kubeconfig string) func(context.Context, *envconf.Config, *testing.T) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config, t *testing.T) (context.Context, error) {
		kubectlOptions := k8s.NewKubectlOptions("", kubeconfig, "")
		k8s.RunKubectl(t, kubectlOptions, "describe", "node")
		t.Logf("Kube config: %s", kubeconfig)
		return ctxopts.WithKubectlOptions(ctx, kubectlOptions), nil
	}
}

type kindContextKey string

func CreateKindCluster() func(context.Context, *envconf.Config, *testing.T) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config, t *testing.T) (context.Context, error) {
		clusterName := strings.NameFromT(t)
		k := kind.NewCluster(clusterName)

		// We only provide the config because the API is constructed in such a way
		// that it requires both the image and the cluster config.
		kubecfg, err := k.CreateWithConfig(os.Getenv(internal.EnvNameKindImage), "yamls/cluster.yaml")
		if err != nil {
			return ctx, err
		}

		kubectlOptions := k8s.NewKubectlOptions("", kubecfg, "")
		k8s.WaitUntilAllNodesReady(t, kubectlOptions, 60, 2*time.Second)
		k8s.RunKubectl(t, kubectlOptions, "describe", "node")
		ctx = ctxopts.WithKubectlOptions(ctx, kubectlOptions)
		t.Logf("Kube config: %s", kubecfg)

		// update envconfig with kubeconfig...
		cfg.WithKubeconfigFile(kubecfg)

		// ...and with new klient.Client since otherwise it would be reused as per:
		// https://github.com/kubernetes-sigs/e2e-framework/blob/55d8b7e4/pkg/envconf/config.go#L116-L132
		cl, err := klient.NewWithKubeConfigFile(kubecfg)
		if err != nil {
			return ctx, err
		}
		cfg.WithClient(cl)

		// store entire cluster value in ctx for future access using the cluster name
		return context.WithValue(ctx, kindContextKey(clusterName), k), nil
	}
}

func DestroyKindCluster() func(context.Context, *envconf.Config, *testing.T) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config, t *testing.T) (context.Context, error) {
		clusterName := strings.NameFromT(t)
		clusterVal := ctx.Value(kindContextKey(clusterName))
		if clusterVal == nil {
			return ctx, fmt.Errorf("destroy kind cluster func: context cluster is nil")
		}

		cluster, ok := clusterVal.(*kind.Cluster)
		if !ok {
			return ctx, fmt.Errorf("destroy kind cluster func: unexpected type for cluster value")
		}

		if err := cluster.Destroy(); err != nil {
			return ctx, fmt.Errorf("destroy kind cluster: %w", err)
		}

		return ctx, nil
	}
}
