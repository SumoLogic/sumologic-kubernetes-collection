package main

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"sigs.k8s.io/e2e-framework/pkg/env"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/support/kind"
)

const (
	envNameUseKubeConfig = "USE_KUBECONFIG"
	envNameKubeConfig    = "KUBECONFIG"
)

var (
	testenv env.Environment
)

func TestMain(m *testing.M) {
	if len(os.Getenv(envNameUseKubeConfig)) > 0 {
		testenv = env.NewWithKubeConfig(os.Getenv(envNameKubeConfig))
	} else {
		testenv = env.New()
		kindClusterName := generateID("cluster")

		// Use pre-defined environment funcs to create a kind cluster prior to test run
		testenv.Setup(
			CreateKindCluster(kindClusterName),
		)

		// Use pre-defined environment funcs to teardown kind cluster after tests
		testenv.Finish(
			DestroyKindCluster(kindClusterName),
		)
	}

	os.Exit(testenv.Run(m))
}

type kindContextKey string

func CreateKindCluster(clusterName string) env.Func {
	return func(ctx context.Context, cfg *envconf.Config) (context.Context, error) {
		k := kind.NewCluster(clusterName)
		// We only provide the config because the API is constructed in such a way
		// that it requires both the image and the cluster config.
		kubecfg, err := k.CreateWithConfig(KindImages.Default, "yamls/cluster.yaml")
		if err != nil {
			return ctx, err
		}

		// TODO: find a better way than sleeping here, e.g. to wait for specific
		// k8s subsystems to be avialable.

		// stall, wait for pods initializations
		time.Sleep(3 * time.Second)

		// update envconfig  with kubeconfig
		cfg.WithKubeconfigFile(kubecfg)

		// store entire cluster value in ctx for future access using the cluster name
		return context.WithValue(ctx, kindContextKey(clusterName), k), nil
	}
}

func DestroyKindCluster(name string) env.Func {
	return func(ctx context.Context, cfg *envconf.Config) (context.Context, error) {
		clusterVal := ctx.Value(kindContextKey(name))
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

func generateID(prefix string) string {
	return envconf.RandomName(prefix, 14)
}
