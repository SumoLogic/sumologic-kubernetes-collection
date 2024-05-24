package ctxopts

import (
	"context"
	"fmt"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
)

type ctxKey string

const (
	ctxKeyNameKubectlOptions ctxKey = "kubectloptions"
	ctxKeyNameHelmOptions    ctxKey = "helmoptions"
	ctxKeyNameHelmRelease    ctxKey = "helmrelease"
	ctxKeyNameNamespace      ctxKey = "namespace"
	ctxKeyNameKindClusters   ctxKey = "kindClusters"
)

func WithKubectlOptions(ctx context.Context, kubectlOptions *k8s.KubectlOptions) context.Context {
	return context.WithValue(ctx, ctxKeyNameKubectlOptions, kubectlOptions)
}

func KubectlOptions(ctx context.Context) *k8s.KubectlOptions {
	v := ctx.Value(ctxKeyNameKubectlOptions)
	return v.(*k8s.KubectlOptions)
}

func WithHelmOptions(ctx context.Context, helmOptions *helm.Options) context.Context {
	return context.WithValue(ctx, ctxKeyNameHelmOptions, helmOptions)
}

func HelmOptions(ctx context.Context) *helm.Options {
	v := ctx.Value(ctxKeyNameHelmOptions)
	return v.(*helm.Options)
}

func WithNamespace(ctx context.Context, namespace string) context.Context {
	return context.WithValue(ctx, ctxKeyNameNamespace, namespace)
}

func Namespace(ctx context.Context) string {
	v := ctx.Value(ctxKeyNameNamespace)
	return v.(string)
}

func WithHelmRelease(ctx context.Context, namespace string) context.Context {
	return context.WithValue(ctx, ctxKeyNameHelmRelease, namespace)
}

func HelmRelease(ctx context.Context) string {
	v := ctx.Value(ctxKeyNameHelmRelease)
	return v.(string)
}

func AdditionalSumologicMockNamespace(ctx context.Context) string {
	v := ctx.Value(ctxKeyNameHelmRelease)
	return fmt.Sprintf("%s-sumologic-mock", v.(string))
}

func Clusters(ctx context.Context) []string {
	v := ctx.Value(ctxKeyNameKindClusters)
	if v == nil {
		return []string{}
	}
	return v.([]string)
}

func WithCluster(ctx context.Context, clusterName string) context.Context {
	clusters := Clusters(ctx)
	clusters = append(clusters, clusterName)
	return context.WithValue(ctx, ctxKeyNameKindClusters, clusters)
}

func WithoutCluster(ctx context.Context, clusterName string) context.Context {
	clusters := Clusters(ctx)
	index := -1
	for i, cluster := range clusters {
		if cluster == clusterName {
			index = i
		}
	}
	if index == -1 {
		return ctx
	}

	clusters[index] = clusters[len(clusters)-1]
	clusters = clusters[:len(clusters)-1]
	return context.WithValue(ctx, ctxKeyNameKindClusters, clusters)
}
