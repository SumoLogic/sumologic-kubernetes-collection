#!/bin/bash

set -euo pipefail

PROM_POD="$(kubectl get pods --all-namespaces | grep -i prometheus-0 | awk '{print $2}')"

kubectl -n sumologic port-forward "${PROM_POD}" --address 0.0.0.0 9090:9090
