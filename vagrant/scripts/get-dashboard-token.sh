#!/bin/bash

set -euo pipefail

kubectl -n kube-system describe secret default | awk '$1=="token:"{print $2}'
