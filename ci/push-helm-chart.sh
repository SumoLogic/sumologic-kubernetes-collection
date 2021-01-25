#!/usr/bin/env bash

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"
# shellcheck disable=SC1090
source "${ROOT_DIR}"/ci/_build_functions.sh

fetch_current_branch
VERSION="$(git describe --tags --abbrev=40)"
readonly VERSION="${VERSION#v}"

pushd "${ROOT_DIR}" || exit 1
echo "Starting to push helm chart in: $(pwd) with version tag: ${VERSION}"

set_up_github

if is_checkout_on_tag; then
  push_helm_chart "${VERSION}" "."
else
  push_helm_chart "${VERSION}" "./dev"
fi

popd || exit 1

echo "DONE"
