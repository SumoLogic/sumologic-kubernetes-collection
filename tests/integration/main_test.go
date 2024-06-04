package integration

import (
	"context"
	"fmt"
	"log"
	"os"
	"testing"

	"sigs.k8s.io/e2e-framework/pkg/env"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/envfuncs"
	"sigs.k8s.io/e2e-framework/support"
	"sigs.k8s.io/e2e-framework/support/kind"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/stepfuncs"
)

const (
	envNameUseKubeConfig        = "USE_KUBECONFIG"
	envNameKubeConfig           = "KUBECONFIG"
	envNameImageArchive         = "IMAGE_ARCHIVE"
	defaultImageArchiveFilename = "images.tar"
	kindClusterConfigPath       = "yamls/cluster.yaml"
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
			ConfigureTestEnv(testenv)
		} else {
			kindProvider, err := GetKindProvider()
			if err != nil {
				log.Fatal(err)
			}
			clusterOpts := GetClusterOpts()
			testenv.Setup(envfuncs.CreateClusterWithConfig(kindProvider, kindClusterName, kindClusterConfigPath, clusterOpts...))
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
		stepfuncs.KubectlCreateOperatorNamespacesOpt(),
		stepfuncs.KubectlCreateOverrideNamespaceOpt(),
		stepfuncs.HelmVersionOpt(),
		stepfuncs.HelmDependencyUpdateOpt(internal.HelmSumoLogicChartAbsPath),
		// HelmInstallTestOpt picks a values file from `values` directory
		// based on the test name ( the details of name generation can be found
		// in `strings.ValueFileFromT()`.)
		// This values file will be used throughout the test to install the
		// collection's chart.
		//
		// The reason for this is to limit the amount of boilerplate in tests
		// themselves but we cannot attach/map the values.yaml to the test itself
		// so we do this mapping instead.
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

func GetClusterOpts() []support.ClusterOpts {
	clusterOpts := []support.ClusterOpts{}
	image := os.Getenv(internal.EnvNameKindImage)
	clusterOpts = append(clusterOpts, kind.WithImage(image))
	return clusterOpts
}

func GetKindProvider() (support.E2EClusterProviderWithImageLoader, error) {
	provider := kind.NewProvider().(support.E2EClusterProviderWithImageLoader)

	// load the Docker image archive if present
	fileName, err := GetImageArchiveFilename()
	if err != nil {
		log.Printf("Couldn't find image archive file %s, proceeding without it", fileName)
		return provider, nil
	}

	err = provider.LoadImageArchive(context.TODO(), fileName)
	if err != nil {
		return nil, fmt.Errorf("Loading image archive failed: %w", err)
	}
	log.Printf("Loaded image archive: %s", fileName)

	return provider, nil
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
