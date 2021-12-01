package main

import (
	"fmt"
	"time"
)

func generateNamespaceName(t time.Time) string {
	return fmt.Sprintf("ns-test-%d", t.Unix())
}

func generateReleaseName(t time.Time) string {
	return fmt.Sprintf("release-test-%d", t.Unix())
}
