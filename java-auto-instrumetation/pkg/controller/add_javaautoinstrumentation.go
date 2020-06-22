package controller

import (
	"github.com/SumoLogic/sumologic-kubernetes-collection/java-auto-instrumentation/pkg/controller/javaautoinstrumentation"
)

func init() {
	// AddToManagerFuncs is a list of functions to create controllers and add them to a manager.
	AddToManagerFuncs = append(AddToManagerFuncs, javaautoinstrumentation.Add)
}
