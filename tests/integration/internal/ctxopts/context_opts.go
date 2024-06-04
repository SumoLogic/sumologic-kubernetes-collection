package ctxopts

import (
	"context"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
)

type ctxKey string

const (
	ctxKeyNameNamespace ctxKey = "namespace"
)

func KubectlOptions(ctx context.Context, envConf *envconf.Config) *k8s.KubectlOptions {
	namespace := Namespace(ctx)
	return k8s.NewKubectlOptions("", envConf.KubeContext(), namespace)
}

// NOTE: It's possible to put the namespace in the environment config instead, but this makes running tests in parallel impossible.
// Each test gets its own copy of the context, but they use the same environment config.
func WithNamespace(ctx context.Context, namespace string) context.Context {
	return context.WithValue(ctx, ctxKeyNameNamespace, namespace)
}

func Namespace(ctx context.Context) string {
	v := ctx.Value(ctxKeyNameNamespace)
	if v == nil {
		return ""
	}
	return v.(string)
}
