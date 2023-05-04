#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(dirname "$(dirname "${0}")")"
readonly ROOT_DIR="${ROOT_DIR}"

# shellcheck disable=SC1090,SC1091
source "${ROOT_DIR}"/ci/_build_functions.sh

fetch_current_branch
RELEASE_VERSION="$(git describe --tags --abbrev=10)"
readonly RELEASE_VERSION="${RELEASE_VERSION#v}"
DEV_VERSION="$(git describe --tags --long --abbrev=10)"
readonly DEV_VERSION="${DEV_VERSION#v}"

pushd "${ROOT_DIR}" || exit 1

set_up_github

PWD=$(pwd)
echo "Pushing helm chart in: ${PWD} with version tag: ${DEV_VERSION} to the dev catalog"
push_helm_chart "${DEV_VERSION}" "./dev"

echo "Pruning the dev Helm Chart releases older than one month"
max_age_timestamp="$(date --date="-1 month" +"%s")"
major_version_number=$(echo "${DEV_VERSION}" | cut -dv -f2 | cut -d. -f1)
prune_helm_releases "./dev" "${max_age_timestamp}" "${major_version_number}"

# shellcheck disable=SC2310
if is_checkout_on_tag; then
  echo "Pushing helm chart in: ${PWD} with version tag: ${RELEASE_VERSION} to the release catalog"
  push_helm_chart "${RELEASE_VERSION}" "."
fi

popd || exit 1

echo "DONE"
