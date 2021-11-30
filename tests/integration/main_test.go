package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"testing"
	"time"

	"sigs.k8s.io/e2e-framework/pkg/env"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/support/kind"

	"github.com/gruntwork-io/terratest/modules/k8s"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
)

const (
	envNameUseKubeConfig = "USE_KUBECONFIG"
	envNameKubeConfig    = "KUBECONFIG"
)

var (
	testenv env.Environment
)

func TestMain(m *testing.M) {
	internal.InitializeConstants()

	if useKubeConfig := os.Getenv(envNameUseKubeConfig); len(useKubeConfig) > 0 {
		testenv = env.
			NewWithKubeConfig(os.Getenv(envNameKubeConfig)).
			BeforeEachTest(InjectKubeconfigFromEnv())
	} else {
		cfg, err := envconf.NewFromFlags()
		if err != nil {
			log.Fatalf("envconf.NewFromFlags() failed: %s", err)
		}
		testenv = env.NewWithConfig(cfg)

		testenv.BeforeEachTest(
			CreateKindCluster(),
		)

		testenv.AfterEachTest(
			DestroyKindCluster(),
		)
	}

	os.Exit(testenv.Run(m))
}

func InjectKubeconfigFromEnv() func(context.Context, *envconf.Config, *testing.T) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config, t *testing.T) (context.Context, error) {
		kubecfg := os.Getenv(envNameKubeConfig)
		kubectlOptions := k8s.NewKubectlOptions("", kubecfg, "")
		k8s.RunKubectl(t, kubectlOptions, "describe", "node")
		t.Logf("Kube config: %s", kubecfg)
		return ctxopts.WithKubectlOptions(ctx, kubectlOptions), nil
	}
}

type kindContextKey string

func CreateKindCluster() func(context.Context, *envconf.Config, *testing.T) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config, t *testing.T) (context.Context, error) {
		clusterName := clusterNameFromT(t)
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

		// update envconfig with kubeconfig
		cfg.WithKubeconfigFile(kubecfg)

		// store entire cluster value in ctx for future access using the cluster name
		return context.WithValue(ctx, kindContextKey(clusterName), k), nil
	}
}

func DestroyKindCluster() func(context.Context, *envconf.Config, *testing.T) (context.Context, error) {
	return func(ctx context.Context, cfg *envconf.Config, t *testing.T) (context.Context, error) {
		clusterName := clusterNameFromT(t)
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

func clusterNameFromT(t *testing.T) string {
	return strings.ReplaceAll(strings.ToLower(t.Name()), "_", "-")
}
