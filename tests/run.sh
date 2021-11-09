#!/usr/bin/env bash

readonly SCRIPT_PATH="$( dirname "$(realpath "${0}")" )"
readonly CONFIG_FILES=$(find "${SCRIPT_PATH}"/* -maxdepth 1 -name 'config.sh')

if ! docker info >/dev/null 2>&1 ; then
  echo "Docker unavailable. Please start the daemon and rerun tests"
  echo "Error:"
  echo
  docker info
  exit 1
fi

# shellcheck disable=SC1090
# shellcheck source=tests/functions.sh
source "${SCRIPT_PATH}/functions.sh"

export TEST_SUCCESS=true

# prepare_environment "${SCRIPT_PATH}/../deploy/helm/sumologic"

if [[ -f "${SCRIPT_PATH}/shared_config.sh" ]] ; then
  echo "Sourcing ${SCRIPT_PATH}/shared_config.sh for all tests envs"
  # shellcheck source=tests/shared_config.sh
  source "${SCRIPT_PATH}/shared_config.sh"
fi

for config_file in ${CONFIG_FILES}; do
  # add a subshell to not inherit previous tests' envs
  (
    test_dir="$( dirname "$(realpath "${config_file}")" )"
    echo "Performing tests for $(basename "${test_dir}")"
    # shellcheck disable=SC1090
    source "${config_file}"
    set_variables "${test_dir}"
    prepare_tests
    perform_tests
    cleanup_tests
  )
done

if [[ "${TEST_SUCCESS}" = "true" ]]; then
  exit 0
else
  exit 1
fi
