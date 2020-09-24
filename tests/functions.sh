#!/bin/bash

function test_start() {
  echo -e "[.] $*";
}

function test_passed() {
  echo -e "[+] $*";
}

function test_failed() {
  echo -e "[-] $*";
}

# Set variables used by the test
function set_variables() {
  # Path to the tests directory
  TEST_SCRIPT_PATH="${1}"
  # Path to the static files (input and output)
  TEST_STATICS_PATH="${TEST_SCRIPT_PATH}/static"
  # Path to the temporary directory (created by the prepare_tests)
  TEST_TMP_PATH="${TEST_SCRIPT_PATH}/tmp"
  # List of test input files (names only)
  TEST_INPUT_FILES="$(find "${TEST_STATICS_PATH}" -name '*input*' -exec basename {} \;)"
  # Path to the temporary output file
  TEST_OUT="${TEST_TMP_PATH}/new_values.yaml"
  # Current version wchich should override the placeholder in test
  CURRENT_CHART_VERSION=$(yq r "${TEST_SCRIPT_PATH}/../../deploy/helm/sumologic/Chart.yaml" version)
}

# Update helm chart and remove the tmpcharts eventually
function prepare_environment() {
  local repo_path=${1}
  rm -rf "${repo_path}/tmpcharts"
  docker run --rm \
    -v "${repo_path}":/chart \
    sumologic/kubernetes-tools:master \
    helm dependency update /chart
}

# Prepare temporary directory for tests
function prepare_tests() {
  mkdir -p "${TEST_TMP_PATH}"
}

# Remove temporary directory
function cleanup_tests() {
  if [[ -n "${TEST_TMP_PATH}" ]]; then
    rm -rf "${TEST_TMP_PATH}"
  fi

  for env_name in  $(env | grep -oE '^TEST_.*?=' | sed 's/=//g'); do
    unset "${env_name}"
  done
}

# Patch tests with current helm chart version
function patch_test() {
  local input_file="${1}"
  local output_file="${2}"
  sed "s/%CURRENT_CHART_VERSION%/${CURRENT_CHART_VERSION}/g" "${input_file}" > "${output_file}"
}

# Generate output file basing on the input values.yaml
function generate_file {
  local template_name="${1}"

  docker run --rm \
    -v "${TEST_SCRIPT_PATH}/../../deploy/helm/sumologic":/chart \
    -v "${TEST_STATICS_PATH}/${input_file}":/values.yaml \
    sumologic/kubernetes-tools:master \
    helm template /chart -f /values.yaml \
      --namespace sumologic \
      --set sumologic.accessId='accessId' \
      --set sumologic.accessKey='accessKey' \
      -s "${template_name}" 2>/dev/null 1> "${TEST_OUT}"
}

# Run test
function perform_test {
  local input_file="${1}"
  local template_name="${2}"

  test_name="${input_file//.input.yaml/}"
  output_file="${test_name}.output.yaml"

  patch_test "${TEST_STATICS_PATH}/${output_file}" "${TEST_TMP_PATH}/${output_file}"

  test_start "${test_name}"
  generate_file "${template_name}"

  test_output=$(diff "${TEST_TMP_PATH}/${output_file}" "${TEST_OUT}" | cat -te)
  rm "${TEST_OUT}"

  if [[ -n "${test_output}" ]]; then
    echo -e "\tOutput diff (${TEST_STATICS_PATH}/${output_file}):\n${test_output}"
    test_failed "${test_name}"
    # Set all tests as failed
    # This env comes from run.sh
    export TEST_SUCCESS=1
  else
    test_passed "${test_name}"
  fi
}

# Perform tests from the directory using TEST_INPUT_FILES
function perform_tests {
  for input_file in ${TEST_INPUT_FILES}; do
    perform_test "${input_file}" "${TEST_TEMPLATE}"
  done
}
