package logsgenerator

import (
	"fmt"
	"strings"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

/// This package wraps the logsgenerator utility in sumologic-kubernetes-tools in a procedural API
/// easily consumable by tests.

const deploymentSleepTime = time.Hour * 24 // how much time we spend sleeping after generating logs in a Deployment

type LogsGeneratorOptions struct {
	// For all of these options, 0 and "" respectively are treated as "not set"

	// how long we should run in total
	// the way Duration and TotalLogs interact, is that the program exits on the first condition achieved
	// in particular, there isn't a way to make it continue running after generating a fixed number of logs
	Duration uint
	// how many log lines to generate in total
	TotalLogs uint
	// maximum number of logs generated per second
	LogsThroughput uint
	// maximum number of bytes generater per second
	BytesThroughput uint
	// should we print diagnostic messages?
	Verbose bool

	// Pattern options
	// See https://github.com/SumoLogic/sumologic-kubernetes-tools/tree/main/src/rust/logs-generator#patterns

	// These options control random pattern generation
	RandomPatterns      uint
	MinPatternLength    uint
	MaxPatternLength    uint
	KnownWordsInRatio   uint
	RandomWordsInRatio  uint
	RandomDigitsInRatio uint

	// This option allows the pattern to be controlled directly
	Pattern string
}

func NewDefaultGeneratorOptions() *LogsGeneratorOptions {
	return &LogsGeneratorOptions{
		Duration:            0,
		TotalLogs:           0,
		LogsThroughput:      0,
		BytesThroughput:     0,
		Verbose:             false,
		RandomPatterns:      10,
		MinPatternLength:    5,
		MaxPatternLength:    20,
		KnownWordsInRatio:   7,
		RandomWordsInRatio:  2,
		RandomDigitsInRatio: 1,
		Pattern:             "",
	}
}

func GetLogsGeneratorDeployment(
	namespace string,
	name string,
	image string,
	options LogsGeneratorOptions,
) appsv1.Deployment {
	var replicas int32 = 1
	appLabels := map[string]string{
		"app": name,
	}
	metadata := metav1.ObjectMeta{
		Name:      name,
		Namespace: namespace,
		Labels:    appLabels,
	}

	// There's no way to tell the log generator to keep running after it's done generating logs. This is annoying if
	// we want to run it in a Deployment and not have it be restarted after exiting. So we sleep after it exits.
	generatorArgs := optionsToArgumentList(options)
	logsGeneratorCommand := fmt.Sprintf("logs-generator %s", strings.Join(generatorArgs, " "))
	logsGeneratorAndSleepCommand := fmt.Sprintf("%s; sleep %f", logsGeneratorCommand, deploymentSleepTime.Seconds())

	podTemplateSpec := corev1.PodTemplateSpec{
		ObjectMeta: metadata,
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:    name,
					Image:   image,
					Command: []string{"/bin/bash", "-c", "--"},
					Args:    []string{logsGeneratorAndSleepCommand},
				},
			},
		},
	}
	return appsv1.Deployment{
		ObjectMeta: metadata,
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: appLabels,
			},
			Template: podTemplateSpec,
		},
	}
}

func optionsToArgumentList(options LogsGeneratorOptions) []string {
	// Note: this could be made cleaner with reflection and struct field tags, but we don't
	// really need the complexity, and this logic is unlikely to change a lot
	args := []string{
		fmt.Sprintf("--duration=%d", options.Duration),
		fmt.Sprintf("--total-logs=%d", options.TotalLogs),
		fmt.Sprintf("--logs-throughput=%d", options.LogsThroughput),
		fmt.Sprintf("--throughput=%d", options.BytesThroughput),
		fmt.Sprintf("--verbose=%v", options.Verbose),
		fmt.Sprintf("--random-patterns=%d", options.RandomPatterns),
		fmt.Sprintf("--min=%d", options.MinPatternLength),
		fmt.Sprintf("--max=%d", options.MaxPatternLength),
		fmt.Sprintf("--known_words=%d", options.KnownWordsInRatio),
		fmt.Sprintf("--random_words=%d", options.RandomWordsInRatio),
		fmt.Sprintf("--random_digits=%d", options.RandomDigitsInRatio),
	}
	if len(options.Pattern) > 0 { // logs-generator doesn't like directly setting an empty pattern
		args = append(args, fmt.Sprintf("--pattern=%q", options.Pattern))
	}
	return args
}
