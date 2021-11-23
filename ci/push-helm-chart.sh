#!/usr/bin/env bash

ROOT_DIR="$(dirname "$(dirname "${0}")")"
readonly ROOT_DIR="${ROOT_DIR}"

# shellcheck disable=SC1090,SC1091
source "${ROOT_DIR}"/ci/_build_functions.sh

fetch_current_branch
RELEASE_VERSION="$(git describe --tags --abbrev=10)"
readonly RELEASE_VERSION="${RELEASE_VERSION#v}"
DEV_VERSION="$(git describe --tags --long)"
readonly DEV_VERSION="${DEV_VERSION#v}"

pushd "${ROOT_DIR}" || exit 1

set_up_github

echo "Pushing helm chart in: $(pwd) with version tag: ${DEV_VERSION} to the dev catalog"
push_helm_chart "${DEV_VERSION}" "./dev"

if is_checkout_on_tag; then
  echo "Pushing helm chart in: $(pwd) with version tag: ${RELEASE_VERSION} to the release catalog"
  push_helm_chart "${RELEASE_VERSION}" "."
fi

popd || exit 1

echo "DONE"
