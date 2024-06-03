package integration

import (
	"context"
	"log"
	"os"
	"testing"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/klient"
	"sigs.k8s.io/e2e-framework/klient/k8s/resources"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/klient/wait/conditions"
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
			testenv.Finish(DestroyKindCluster(kindClusterName))
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
		// Create Test Namespace
		stepfuncs.KubectlCreateNamespaceTestOpt(),
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

		// We only provide the config because the API is constructed in such a way
		// that it requires both the image and the cluster config.
		kubecfg, err := k.CreateWithConfig(os.Getenv(internal.EnvNameKindImage), "yamls/cluster.yaml")
		if err != nil {
			return ctx, err
		}

		// load the Docker image archive if present
		fileName, err := GetImageArchiveFilename()
		if err != nil {
			log.Printf("Couldn't find image archive file %s, proceeding without it", fileName)
		} else {
			err = k.LoadImageArchive(fileName)
			if err != nil {
				log.Fatalf("Loading image archive failed: %v", err)
			}
			log.Printf("Loaded image archive: %s", fileName)
		}

		kubectlOptions := k8s.NewKubectlOptions("", kubecfg, "")
		ctx = ctxopts.WithKubectlOptions(ctx, kubectlOptions)
		log.Printf("Kube config: %s", kubecfg)

		// update envconfig with kubeconfig...
		cfg.WithKubeconfigFile(kubecfg)

		// ...and with new klient.Client since otherwise it would be reused as per:
		// https://github.com/kubernetes-sigs/e2e-framework/blob/55d8b7e4/pkg/envconf/config.go#L116-L132
		cl, err := klient.NewWithKubeConfigFile(kubecfg)
		if err != nil {
			return ctx, err
		}
		cfg.WithClient(cl)

		err = WaitForControlPlane(ctx, cl, k)
		if err != nil {
			return ctx, err
		}

		// store entire cluster value in ctx for future access using the cluster name
		return ctx, nil
	}
}

func DestroyKindCluster(clusterName string) func(context.Context, *envconf.Config) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config) (context.Context, error) {
		cluster := kind.NewCluster(clusterName)
		return ctx, cluster.Destroy()
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

// this is a backport of a function added in e2e_framework 0.3.0
// it should be removed once we upgrade
func WaitForControlPlane(ctx context.Context, client klient.Client, k *kind.Cluster) error {
	r, err := resources.New(client.RESTConfig())
	if err != nil {
		return err
	}
	for _, sl := range []metav1.LabelSelectorRequirement{
		{Key: "component", Operator: metav1.LabelSelectorOpIn, Values: []string{"etcd", "kube-apiserver", "kube-controller-manager", "kube-scheduler"}},
		{Key: "k8s-app", Operator: metav1.LabelSelectorOpIn, Values: []string{"kindnet", "kube-dns", "kube-proxy"}},
	} {
		selector, err := metav1.LabelSelectorAsSelector(
			&metav1.LabelSelector{
				MatchExpressions: []metav1.LabelSelectorRequirement{
					sl,
				},
			},
		)
		if err != nil {
			return err
		}
		err = wait.For(conditions.New(r).ResourceListN(&v1.PodList{}, len(sl.Values), resources.WithLabelSelector(selector.String())))
		if err != nil {
			return err
		}
	}
	return nil
}
