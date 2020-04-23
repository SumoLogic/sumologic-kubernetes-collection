#!/usr/bin/env bash

read -d '' usage << EOF
This image provides a set of tools for Kubernetes Collection. You can use following commands:

 * K8S Check for verifying the environment:

 kubectl run tools --generator=run-pod/v1 -it --rm --restart=Never --image sumologic/kubernetes-tools -- /usr/bin/k8scheck.sh

 * Interactive mode:

 kubectl run tools --generator=run-pod/v1 -it --rm --restart=Never --image sumologic/kubernetes-tools -- /bin/bash -l
EOF

echo "$usage"