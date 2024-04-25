#!/usr/bin/env bash
set -x
SRC_REPOSITORY=${1}
DESTINATION_NAMESPACE=${2}

docker run \
    -v ~/.docker/config.json:/tmp/auth.json \
    quay.io/skopeo/stable:v1.15.0 \
        sync \
            --all \
            --keep-going \
            --retry-times 5 \
            --src docker \
            --dest docker \
            "${SRC_REPOSITORY}" \
            "${DESTINATION_NAMESPACE}"
