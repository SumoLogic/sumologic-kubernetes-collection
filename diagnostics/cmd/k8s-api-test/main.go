// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"log"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func main() {
    handleErr := func(message string, err error) {
		if err != nil {
			log.Fatalf("%s: %v\n", message, err)
		}
    }

    config, err := rest.InClusterConfig()
    handleErr("Failed when creating in-cluster K8S config", err)

    clientset, err := kubernetes.NewForConfig(config)
    handleErr("Failed when connecting to K8S cluster", err)

    version, err := clientset.Discovery().ServerVersion()
    handleErr("Failed when pulling version info", err)
    log.Printf("Kubernetes version: %s", version.GitVersion)

    pods, err := clientset.CoreV1().Pods("").List(metav1.ListOptions{Limit: 20})
    handleErr("Failed when fetching list of pods", err)

    log.Printf("Received data for %d pods in the cluster\n", len(pods.Items))
}
