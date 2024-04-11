package stepfuncs

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal/curlapp"
)

// Make curl calls using a job.
func MakeCurl(
	maxSleepInterval uint,
	maxWaitTime uint,
	curlappName string,
	curlappNamespace string,
	curlappImage string,
) features.Func {
	return func(ctx context.Context, t *testing.T, envConf *envconf.Config) context.Context {
		client := envConf.Client()
		curlOpts := *curlapp.NewDefaultCurlAppOptions()
		curlOpts.MaxWaitTime = maxWaitTime
		curlOpts.SleepInterval = maxSleepInterval

		var namespace corev1.Namespace
		err := client.Resources().Get(ctx, curlappNamespace, "", &namespace)
		if err != nil {
			// create the namespace
			namespace := corev1.Namespace{ObjectMeta: metav1.ObjectMeta{Name: curlappNamespace}}
			require.NoError(t, client.Resources().Create(ctx, &namespace))
		}

		job := curlapp.GetCurlAppJob(
			ctx,
			curlappNamespace,
			curlappName,
			curlappImage,
			curlOpts,
		)

		// create the deployment
		err = client.Resources(curlappNamespace).Create(ctx, &job)
		require.NoError(t, err)

		return ctx
	}
}
