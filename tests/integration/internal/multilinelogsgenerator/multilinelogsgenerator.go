package multilinelogsgenerator

import (
	"fmt"
	"time"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	cmdGenRandomString    = "LONG_STRING=\"$(cat /dev/urandom | tr -dc ''a-z0-9'' | head -c 30000)\";"
	shScriptTemplate      = cmdGenRandomString + "%s sleep 3600"
	image                 = "bash:4.4"
	timestampFormat       = "Jan 2 15:04:05"
	singleLineLogTemplate = "echo -e '%s single line log No. %d';"
	multiLineLogTemplate  = `echo -e '%s Exception in thread "main" java.lang.RuntimeException: Something has gone wrong, aborting! ${LONG_STRING} end of the 1st long line';
	echo -e '    at com.myproject.module.MyProject.badMethod(MyProject.java:22)';
	echo -e '    at com.myproject.module.MyProject.oneMoreMethod(MyProject.java:18)';
	echo -e '    at com.myproject.module.MyProject.anotherMethod(MyProject.java:14)';
	echo -e '    at com.myproject.module.MyProject.someMethod(MyProject.java:10)';
	echo -e '    at com.myproject.module.MyProject.verylongLine(MyProject.java:100000) ${LONG_STRING} end of the 2nd long line';
	echo -e '    at com.myproject.module.MyProject.main(MyProject.java:6)';
`
)

func generateSingleLineLogRecords(count int) string {
	logs := ""
	for i := 0; i <= count; i++ {
		timestamp := time.Now().Format(timestampFormat)
		logs += fmt.Sprintf(singleLineLogTemplate, timestamp, i)
	}
	return logs
}

func generateMultiLineLogRecords(count int) string {
	logs := ""
	for i := 0; i <= count; i++ {
		timestamp := time.Now().Format(timestampFormat)
		logs += fmt.Sprintf(multiLineLogTemplate, timestamp)
	}
	return logs
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
	args := fmt.Sprintf(shScriptTemplate, logs)
	podSpec := corev1.PodSpec{
		Containers: []corev1.Container{
			{
				Name:  name,
				Image: image,
				//Command: []string{"/bin/sh", "-c", "--"},
				Args: []string{args},
			},
		},
	}

	return corev1.Pod{
		ObjectMeta: metadata,
		Spec:       podSpec,
	}
}
