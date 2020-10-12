#!/bin/bash

readonly SCRIPT_PATH="$( dirname "$(realpath "${0}")" )"
readonly CONFIG_FILES=$(find "${SCRIPT_PATH}"/* -maxdepth 1 -name 'config.sh')
# shellcheck disable=SC1090
source "${SCRIPT_PATH}/functions.sh"

export TEST_SUCCESS=true

prepare_environment "${SCRIPT_PATH}/../deploy/helm/sumologic"

for config_file in ${CONFIG_FILES}; do
  test_dir="$( dirname "$(realpath "${config_file}")" )"
  echo "Performing tests for $(basename "${test_dir}")"
  # shellcheck disable=SC1090
  source "${config_file}"
  set_variables "${test_dir}"
  prepare_tests
  perform_tests
  cleanup_tests
done

if [[ "${TEST_SUCCESS}" = "true" ]]; then
  exit 0
else
  exit 1
fi
