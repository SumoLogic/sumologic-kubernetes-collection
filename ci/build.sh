#!/usr/bin/env bash

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"
# shellcheck disable=SC1090
source "${ROOT_DIR}"/ci/_build_functions.sh

fetch_current_branch
VERSION="$(git describe --tags)"
readonly VERSION="${VERSION#v}"

: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"

pushd "${ROOT_DIR}" || exit 1
echo "Starting build in: $(pwd) with version tag: ${VERSION}"

bundle_fluentd_plugins "${VERSION}" || (echo "Failed bundling fluentd plugins" && exit 1)
build_docker_image "${DOCKER_TAG}" || (echo "Error during building docker image" && exit 1)

popd || exit 1

echo "DONE"
