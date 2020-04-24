#!/usr/bin/env bash

function check_file() {
  if [[ -f $1 ]]; then
    size=$(stat -L -c %s $1)
    echo "$1 exists, size=${size}"

    if [ "$2" == "true" ]; then
      contents="$(cat $1)"
      echo "$1 contents: $contents"
    fi
  else
    echo "$1 does not exist"
  fi
}

function check_env() {
  if [[ -v $1 ]]; then
    echo "$1 is set"
  else
    echo "$1 is not set"
  fi
}

check_file /var/run/secrets/kubernetes.io/serviceaccount/token
check_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
check_file /var/run/secrets/kubernetes.io/serviceaccount/namespace true

check_env KUBERNETES_SERVICE_HOST
check_env KUBERNETES_SERVICE_PORT
check_env POD_NAMESPACE
echo "POD_NAMESPACE env variable: ${POD_NAMESPACE}"
echo "Kubernetes cluster at $KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT"

echo "Running K8S API test"

/usr/bin/k8s-api-test