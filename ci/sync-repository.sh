#!/usr/bin/env bash

SRC_REPOSITORY=${1}
DESTINATION_NAMESPACE=${2}
skopeo sync \
    -f v2s2 \
    --retry-times 5 \
    --src docker \
    --dest docker \
    "${SRC_REPOSITORY}" \
    "${DESTINATION_NAMESPACE}"
