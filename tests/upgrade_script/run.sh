#!/usr/bin/env bash

# Test generation:
# export test_name=example_test; \
# bash deploy/helm/sumologic/upgrade-1.0.0.sh \
#   tests/upgrade_script/static/${test_name}.input.yaml \
#   1> tests/upgrade_script/static/${test_name}.log 2>&1 \
# && cp new_values.yaml tests/upgrade_script/static/${test_name}.output.yaml

SCRIPT_PATH="$( dirname "$(realpath "${0}")" )"

# shellcheck disable=SC1090
source "${SCRIPT_PATH}/../functions.sh"
readonly TEST_TMP_OUT="${SCRIPT_PATH}/tmp/out.log"

set_variables "${SCRIPT_PATH}"
# reassign variables from set_variables
TEST_SCRIPT_PATH="${TEST_SCRIPT_PATH}"
TEST_STATICS_PATH="${TEST_STATICS_PATH}"
TEST_INPUT_FILES="${TEST_INPUT_FILES}"
TEST_OUT="${TEST_OUT}"

prepare_tests

TEST_SUCCESS=true
for input_file in ${TEST_INPUT_FILES}; do
  test_name="${input_file//.input.yaml/}"
  output_file="${test_name}.output.yaml"
  log_file="${test_name}.log"

  test_start "${test_name}"
  bash "${TEST_SCRIPT_PATH}/../../deploy/helm/sumologic/upgrade-1.0.0.sh" "${TEST_STATICS_PATH}/${input_file}" 1>"${TEST_TMP_OUT}" 2>&1
  mv new_values.yaml "${TEST_OUT}"

  test_output=$(diff "${TEST_STATICS_PATH}/${output_file}" "${TEST_OUT}")
  test_log=$(diff "${TEST_STATICS_PATH}/${log_file}" "${TEST_TMP_OUT}")
  rm "${TEST_TMP_OUT}" "${TEST_OUT}"

  if [[ -n "${test_output}" || -n "${test_log}" ]]; then
    if [[ -n "${test_output}" ]]; then
      echo -e "\tOutput diff (${TEST_STATICS_PATH}/${output_file}):\n${test_output}"
    fi
    if [[ -n "${test_log}" ]]; then
      echo -e "\tLog diff (${TEST_STATICS_PATH}/${log_file}):\n${test_log}"
    fi
    test_failed "${test_name}"
    TEST_SUCCESS=false
  else
    test_passed "${test_name}"
  fi
done

cleanup_tests

if [[ "${TEST_SUCCESS}" = "true" ]]; then
  exit 0
else
  exit 1
fi
