package integration

import (
	"context"
	"log"
	"os"
	"testing"

	"sigs.k8s.io/e2e-framework/pkg/env"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/envfuncs"
	"sigs.k8s.io/e2e-framework/support/kind"

	"github.com/gruntwork-io/terratest/modules/k8s"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

const (
	envNameUseKubeConfig        = "USE_KUBECONFIG"
	envNameKubeConfig           = "KUBECONFIG"
	envNameImageArchive         = "IMAGE_ARCHIVE"
	defaultImageArchiveFilename = "images.tar"
)

var testenv env.Environment

func TestMain(m *testing.M) {
	cfg, err := envconf.NewFromFlags()
	if err != nil {
		log.Fatalf("envconf.NewFromFlags() failed: %s", err)
	}

	testenv = env.NewWithConfig(cfg)
	kindClusterName := envconf.RandomName("sumologic-test", 20)

	if !cfg.DryRunMode() {

		if err := internal.InitializeConstants(); err != nil {
			log.Fatalf("failed initializing constants: %v", err)
		}

		if useKubeConfig := os.Getenv(envNameUseKubeConfig); len(useKubeConfig) > 0 {
			kubeconfig := os.Getenv(envNameKubeConfig)

			cfg.WithKubeconfigFile(kubeconfig)
			testenv = testenv.
				BeforeEachTest(InjectKubectlOptionsFromKubeconfig(kubeconfig))

			ConfigureTestEnv(testenv)
		} else {
			testenv.Setup(CreateKindCluster(kindClusterName))
			ConfigureTestEnv(testenv)
			testenv.Finish(envfuncs.DestroyCluster(kindClusterName))
		}
	}

	os.Exit(testenv.Run(m))
}

func ConfigureTestEnv(testenv env.Environment) {

	// Before

	testenv.Setup(envfuncs.CreateNamespace(internal.LogsGeneratorNamespace))

	for _, f := range stepfuncs.IntoTestEnvFuncs(
		// Needed for OpenTelemetry Operator test
		// TODO: Create namespaces only for specific tests
		stepfuncs.KubectlCreateOperatorNamespacesOpt(),
		stepfuncs.KubectlCreateOverrideNamespaceOpt(),
		stepfuncs.HelmVersionOpt(),
		// SetHelmOptionsTestOpt picks a values file from `values` directory
		// based on the test name ( the details of name generation can be found
		// in `strings.ValueFileFromT()`.)
		// This values file will be used throughout the test to install the
		// collection's chart.
		//
		// The reason for this is to limit the amount of boilerplate in tests
		// themselves but we cannot attach/map the values.yaml to the test itself
		// so we do this mapping instead.
		stepfuncs.HelmDependencyUpdateOpt(internal.HelmSumoLogicChartAbsPath),
		stepfuncs.HelmInstallTestOpt(internal.HelmSumoLogicChartAbsPath),
	) {
		testenv.BeforeEachTest(f)
	}

	// After
	for _, f := range stepfuncs.IntoTestEnvFuncs(
		stepfuncs.PrintClusterStateOpt(),
		stepfuncs.HelmDeleteTestOpt(),
		stepfuncs.KubectlDeleteOverrideNamespaceOpt(),
		stepfuncs.KubectlDeleteOperatorNamespacesOpt(),
		stepfuncs.KubectlDeleteNamespaceTestOpt(false),
	) {
		testenv.AfterEachTest(f)
	}

	// Teardown
	// TODO: Uninstall the Helm Chart here as well
	testenv.Finish(
		func(ctx context.Context, envConf *envconf.Config) (context.Context, error) {
			namespace := ctxopts.Namespace(ctx)
			if namespace == "" {
				return ctx, nil
			}
			return envfuncs.DeleteNamespace(namespace)(ctx, envConf)
		},
		envfuncs.DeleteNamespace(internal.OverrideNamespace),
		envfuncs.DeleteNamespace(internal.LogsGeneratorNamespace),
	)
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

func CreateKindCluster(clusterName string) func(context.Context, *envconf.Config) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config) (context.Context, error) {
		k := kind.NewCluster(clusterName)
		k.WithOpts(kind.WithImage(os.Getenv(internal.EnvNameKindImage)))

		// We only provide the config because the API is constructed in such a way
		// that it requires both the image and the cluster config.
		kubecfg, err := k.CreateWithConfig(ctx, "yamls/cluster.yaml")
		if err != nil {
			return ctx, err
		}

		// load the Docker image archive if present
		fileName, err := GetImageArchiveFilename()
		if err != nil {
			log.Printf("Couldn't find image archive file %s, proceeding without it", fileName)
		} else {
			err = k.LoadImageArchive(ctx, fileName)
			if err != nil {
				log.Fatalf("Loading image archive failed: %v", err)
			}
			log.Printf("Loaded image archive: %s", fileName)
		}

		// update envconfig with kubeconfig...
		cfg.WithKubeconfigFile(kubecfg)

		err = k.WaitForControlPlane(ctx, cfg.Client())
		if err != nil {
			return ctx, err
		}

		kubectlOptions := k8s.NewKubectlOptions("", kubecfg, "")
		ctx = ctxopts.WithKubectlOptions(ctx, kubectlOptions)
		log.Printf("Kube config: %s", kubecfg)

		return ctx, nil
	}
}

func GetImageArchiveFilename() (string, error) {
	fileName := os.Getenv(envNameImageArchive)
	if fileName == "" {
		fileName = defaultImageArchiveFilename
	}

	if _, err := os.Stat(fileName); err != nil {
		return "", err
	}

	return fileName, nil
}
