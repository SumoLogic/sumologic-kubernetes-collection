#!/usr/bin/env bash

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"
# shellcheck disable=SC1090
source "${ROOT_DIR}"/ci/_build_functions.sh

fetch_current_branch
if is_checkout_on_tag; then
  VERSION="$(git describe --tags --always)"
  readonly VERSION="${VERSION#v}"
else
  # Don't use non-tag 'git describe' output as this will
  # fail when building fluentd plugins.
  readonly VERSION="0.0.0"
fi

: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"

echo "Starting build in: $(pwd) with version tag: ${VERSION}"
pushd "${ROOT_DIR}" || exit 1

bundle_fluentd_plugins "${VERSION}" || (echo "Failed bundling fluentd plugins" && exit 1)
build_docker_image "${DOCKER_TAG}" || (echo "Error during building docker image" && exit 1)

popd || exit 1

echo "DONE"
