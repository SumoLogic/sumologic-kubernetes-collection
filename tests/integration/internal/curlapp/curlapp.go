package curlapp

import (
	"context"
	"fmt"
	"strings"

	"github.com/SumoLogic/sumologic-kubernetes-collection/tests/integration/internal"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type CurlAppOpts struct {
	Services      []string
	Namespace     string
	SleepInterval uint
	MaxWaitTime   uint
}

func NewDefaultCurlAppOptions() *CurlAppOpts {
	return &CurlAppOpts{
		Services:      []string{"dotnet-app-service", "java-app-service", "nodejs-app-service", "python-app-service"},
		Namespace:     internal.InstrumentationAppsNamespace,
		SleepInterval: 5,
		MaxWaitTime:   60,
	}
}

func GetCurlAppJob(
	ctx context.Context,
	namespace string,
	name string,
	image string,
	options CurlAppOpts,
) batchv1.Job {
	appLabels := map[string]string{
		"app": name,
	}
	metadata := metav1.ObjectMeta{
		Name:      name,
		Namespace: namespace,
		Labels:    appLabels,
	}

	jobTemplateSpec := corev1.PodTemplateSpec{
		Spec: corev1.PodSpec{
			Containers:    optionsToContainers(ctx, options, name, image),
			RestartPolicy: "Never",
		},
	}

	return batchv1.Job{
		ObjectMeta: metadata,
		Spec: batchv1.JobSpec{
			Template: jobTemplateSpec,
		},
	}
}

func optionsToContainers(ctx context.Context, options CurlAppOpts, name string, image string) []corev1.Container {
	return []corev1.Container{
		{
			Name:    name,
			Image:   image,
			Command: []string{"/bin/bash", "-c"},
			Args: []string{fmt.Sprintf(`
declare -a services=(%s)
max_wait=%d
sleep_interval=%d
counter=0
ready=false
for str in "${services[@]}";
do
    echo ${str}
    is_ready=$(curl -s -o /dev/null -m 3 -L -w ''%%{http_code}'' "http://${str}.%s:8080" )

	if [[ is_ready -eq "200" ]]
	then
	continue
	else
	echo "Waiting for  ${str}"
	sleep $sleep_interval
	counter=$(($counter + $sleep_interval))
	fi

	if [[ "$counter" -gt "$max_wait" ]]
	then
	echo "Couldn't reach ${str}"
	exit 1
	fi
done
`, optsServicesToStr(options.Services), options.MaxWaitTime, options.SleepInterval, options.Namespace)},
		},
	}
}

func optsServicesToStr(services []string) string {
	if len(services) == 0 {
		return ""
	}

	// Check if the slice has only one element.
	if len(services) == 1 {
		return fmt.Sprintf("\"%s\"", services[0])
	}

	quotedSvcs := []string{}
	for _, svc := range services {
		quotedSvcs = append(quotedSvcs, fmt.Sprintf("\"%s\"", svc))
	}

	return strings.Join(quotedSvcs, " ")
}
