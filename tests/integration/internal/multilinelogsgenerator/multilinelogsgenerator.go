package multilinelogsgenerator

import (
	"fmt"
	"math/rand"
	"time"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	bashScriptTemplate    = "%s sleep 3600"
	image                 = "busybox"
	randomStringLength    = 30000
	timestampFormat       = "Jan 2 15:04:05"
	singleLineLogTemplate = "echo '%s single line log No. %d';"
	multiLineLogTemplate  = `echo '%s Exception in thread "main" java.lang.RuntimeException: Something has gone wrong, aborting! %s end of the 1st long line
	at com.myproject.module.MyProject.badMethod(MyProject.java:22)
	at com.myproject.module.MyProject.oneMoreMethod(MyProject.java:18)
	at com.myproject.module.MyProject.anotherMethod(MyProject.java:14)
	at com.myproject.module.MyProject.someMethod(MyProject.java:10)";
	at com.myproject.module.MyProject.verylongLine(MyProject.java:100000) %s end of the 2nd long line";
	at com.myproject.module.MyProject.main(MyProject.java:6)';
`
)

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func init() {
	rand.Seed(time.Now().UnixNano())
}

func generateSingleLineLogRecords(count int) string {
	log := ""
	for i := 0; i <= count; i++ {
		timestamp := time.Now().Format(timestampFormat)
		log += fmt.Sprintf(singleLineLogTemplate, timestamp, i)
	}
	return log
}

func generateRandomString(length int) string {
	b := make([]rune, length)
	for i := range b {
		b[i] = letterRunes[rand.Intn(len(letterRunes))]
	}
	return string(b)
}

func generateMultiLineLogRecords(count int) string {
	log := ""
	for i := 0; i <= count; i++ {
		timestamp := time.Now().Format(timestampFormat)
		randomString := generateRandomString(30000)
		log += fmt.Sprintf(multiLineLogTemplate, timestamp, randomString, randomString)
	}
	return log
}

// generateLogs generates logs in loop,
// logs generated in single loop have following structure:
// block of single line logs, block of multi line logs, block of single line logs
func generateLogs(singlelineLogsBeginningCount int, singlelineLogsEndCount int, multilineLogsCount, logLoopsCount int) string {
	logs := ""
	for i := 0; i <= logLoopsCount; i++ {
		logs += generateSingleLineLogRecords(singlelineLogsBeginningCount)
		logs += generateMultiLineLogRecords(multilineLogsCount)
		logs += generateSingleLineLogRecords(singlelineLogsEndCount)
	}
	return logs
}

func GetMultilineLogsPod(
	namespace string,
	name string,
	singlelineLogsBeginningCount int,
	singlelineLogsEndCount int,
	multilineLogsCount int,
	logLoopsCount int,
) corev1.Pod {
	appLabels := map[string]string{
		"app": name,
	}
	metadata := metav1.ObjectMeta{
		Name:      name,
		Namespace: namespace,
		Labels:    appLabels,
	}

	logs := generateLogs(singlelineLogsBeginningCount, singlelineLogsEndCount, multilineLogsCount, logLoopsCount)
	bashCmd := fmt.Sprintf(bashScriptTemplate, logs)
	podSpec := corev1.PodSpec{
		Containers: []corev1.Container{
			{
				Name:  name,
				Image: image,
				Args:  []string{"/bin/sh", "-c", bashCmd},
			},
		},
	}

	return corev1.Pod{
		ObjectMeta: metadata,
		Spec:       podSpec,
	}
}
