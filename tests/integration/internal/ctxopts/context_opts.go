package ctxopts

import (
	"context"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
)

type ctxKey string

const (
	ctxKeyNameKubectlOptions ctxKey = "kubectloptions"
	ctxKeyNameHelmOptions    ctxKey = "helmoptions"
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
