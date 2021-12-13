package strings

import (
	"fmt"
	"hash/fnv"
	"strings"
	"testing"
)

func NameFromT(t *testing.T) string {
	return strings.ReplaceAll(strings.ToLower(t.Name()), "_", "-")
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
	return fmt.Sprintf("rel-%d", h.Sum32())
}
