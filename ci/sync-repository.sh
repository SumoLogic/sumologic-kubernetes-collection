#!/usr/bin/env bash

SRC_YAML_PATH=${1}
DESTINATION_NAMESPACE=${2}

WORKDIR="$(pwd)"

docker run \
    -v ~/.docker/config.json:/tmp/auth.json \
    -v "${WORKDIR}:/workspace" \
    quay.io/skopeo/stable:v1.15.0 \
        sync \
            --all \
            --keep-going \
            --preserve-digests \
            --retry-times 5 \
            --src yaml \
            --src-no-creds \
            --dest docker \
            "/workspace/${SRC_YAML_PATH}" \
            "${DESTINATION_NAMESPACE}"
