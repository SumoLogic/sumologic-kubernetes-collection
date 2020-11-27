#!/usr/bin/env bash

# shellcheck disable=SC2154

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")/_build_functions.sh"

VERSION="$(git describe --tags --always)"
readonly VERSION="${VERSION#v}"

: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"
: "${DOCKER_USERNAME:=sumodocker}"

if [[ -z "${DOCKER_PASSWORD}" ]]; then
  echo "Provide DOCKER_PASSWORD in order to push built image to container registry"
  exit 1
fi

echo "Starting push in: $(pwd) with version tag: ${VERSION}"

set_up_github
push_docker_image "${VERSION}" "${DOCKER_TAG}"

if is_checkout_on_tag; then
  push_helm_chart "${VERSION}" "."
else
  push_helm_chart "${VERSION}" "./dev"
fi

echo "DONE"
