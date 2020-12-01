#!/usr/bin/env bash

set -e

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"
# shellcheck disable=SC1090
source "${ROOT_DIR}"/ci/_test_functions.sh
# shellcheck disable=SC1090
source "${ROOT_DIR}"/ci/_build_functions.sh

fetch_current_branch
VERSION="$(git describe --tags)"
readonly VERSION="${VERSION#v}"

pushd "${ROOT_DIR}" || exit 1

# Test if template files are generated correctly for various values.yaml
echo "Test helm templates generation"
./tests/run.sh || (echo "Failed testing templates" && exit 1)

# Test upgrade script
echo "Test upgrade script..."
./tests/upgrade_script/run.sh || (echo "Failed testing upgrade script" && exit 1)

# Test upgrade v2 script
echo "Test upgrade v2 script..."
./tests/upgrade_v2_script/run.sh || (echo "Failed testing upgrade v2 script" && exit 1)

# Test fluentd plugins
test_fluentd_plugins "${VERSION}" || (echo "Failed testing fluentd plugins" && exit 1)

popd || exit 1

echo "DONE"
