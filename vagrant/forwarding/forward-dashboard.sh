#!/bin/bash

set -euo pipefail

DASHBOARD_POD="$(kubectl get pods --all-namespaces | grep -i kubernetes-dashboard | awk '{print $2}')"

kubectl -n kube-system port-forward "${DASHBOARD_POD}" --address 0.0.0.0 8443:8443
