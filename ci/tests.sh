#!/usr/bin/env bash

set -e

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"
readonly TESTS_DIR="./tests/helm"

# shellcheck disable=SC1090
source "${ROOT_DIR}"/ci/_build_functions.sh

pushd "${ROOT_DIR}" || exit 1

# Test if template files are generated correctly for various values.yaml
echo "Test helm templates generation"
"${TESTS_DIR}/run.sh" || (echo "Failed testing templates" && exit 1)

# Test upgrade script
echo "Test upgrade script..."
"${TESTS_DIR}/upgrade_script/run.sh" || (echo "Failed testing upgrade script" && exit 1)

# Test upgrade v2 script
echo "Test upgrade v2 script..."
"${TESTS_DIR}/upgrade_v2_script/run.sh" || (echo "Failed testing upgrade v2 script" && exit 1)

popd || exit 1

echo "DONE"
