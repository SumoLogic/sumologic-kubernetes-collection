#!/bin/bash

readonly SCRIPT_PATH="$( dirname $(realpath ${0}) )"
readonly CONFIG_FILES=$(find "${SCRIPT_PATH}"/* -maxdepth 1 -name 'config.sh')
source "${SCRIPT_PATH}/functions.sh"

export TEST_SUCCESS=0

prepare_environment "${SCRIPT_PATH}/../deploy/helm/sumologic"

for config_file in ${CONFIG_FILES}; do
  test_dir="$( dirname $(realpath ${config_file}) )"
  echo "Performing tests for $(basename "${test_dir}")"
  source "${config_file}"
  set_variables "${test_dir}"
  prepare_tests
  perform_tests
  cleanup_tests
done

exit $TEST_SUCCESS
