package strings

import (
	"fmt"
	"hash/fnv"
	"strings"
	"testing"
	"time"
)

const (
	maxReleaseNameLength = 12
)

func NameFromT(t *testing.T) string {
	return strings.ReplaceAll(strings.ToLower(t.Name()), "_", "-")
}

func NamespaceFromT(t *testing.T) string {
	return fmt.Sprintf("%s-%d", NameFromT(t), time.Now().UnixMilli()%1000)
}

func ValueFileFromT(t *testing.T) string {
	testname := strings.ToLower(t.Name())
	testname = strings.TrimPrefix(testname, "test")
	testname = strings.TrimPrefix(testname, "_")
	testname = strings.ReplaceAll(testname, "-", "_")
	return fmt.Sprintf(
		"values_%s.yaml", testname,
	)
}

func ReleaseNameFromT(t *testing.T) string {
	h := fnv.New32a()
	h.Write([]byte(t.Name()))
	return fmt.Sprintf("rel-%d", h.Sum32())[:maxReleaseNameLength]
}
