package stepfuncs

import (
	"context"
	"fmt"
	"strconv"
	"testing"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/ctxopts"
	strings_internal "github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/strings"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"
)

func ChangeMinMaxStatefulsetPods(app string, newMin uint64, newMax uint64) features.Func {
	return func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
		kubectlOptions := ctxopts.KubectlOptions(ctx, c)
		strings_internal.ReleaseNameFromT(t)
		appName := fmt.Sprintf("%s-%s", strings_internal.ReleaseNameFromT(t), app)

		k8s.RunKubectl(t, kubectlOptions, "delete", "hpa", appName)
		k8s.RunKubectl(t, kubectlOptions, "autoscale", "statefulset", appName,
			"--min", strconv.FormatUint(newMin, 10),
			"--max", strconv.FormatUint(newMax, 10),
		)

		return ctx
	}
}
