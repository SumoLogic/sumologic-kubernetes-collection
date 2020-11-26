#!/usr/bin/env bash

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"
# shellcheck disable=SC1090
source "${ROOT_DIR}"/ci/_build_functions.sh

fetch_current_branch
VERSION="$(git describe --tags --always)"
readonly VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/kubernetes-fluentd}"
: "${DOCKER_USERNAME:=sumodocker}"

# shellcheck disable=SC2154
if [[ -z "${DOCKER_PASSWORD}" ]]; then
  echo "Provide DOCKER_PASSWORD in order to push built image to container registry"
  exit 1
fi

echo "Starting push in: $(pwd) with version tag: ${VERSION}"
pushd "${ROOT_DIR}" || exit 1

set_up_github
push_docker_image "${VERSION}" "${DOCKER_TAG}"

if is_checkout_on_tag; then
  push_helm_chart "${VERSION}" "."
else
  push_helm_chart "${VERSION}" "./dev"
fi

popd || exit 1

echo "DONE"
