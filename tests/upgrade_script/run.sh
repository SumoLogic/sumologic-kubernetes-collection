#!/usr/bin/env bash

# Test generation:
# export test_name=example_test; \
# bash deploy/helm/sumologic/upgrade-1.0.0.sh \
#   tests/upgrade_script/static/${test_name}.input.yaml \
#   1> tests/upgrade_script/static/${test_name}.log 2>&1 \
# && cp new_values.yaml tests/upgrade_script/static/${test_name}.output.yaml

SCRIPT_PATH="$( dirname "$(realpath ${0})" )"

source "${SCRIPT_PATH}/../functions.sh"
readonly TEST_TMP_OUT="tmp/out.log"

set_variables "${SCRIPT_PATH}"
prepare_tests

SUCCESS=0
for input_file in ${TEST_INPUT_FILES}; do
  test_name="$(echo "${input_file}" | sed -e 's/.input.yaml$//g')"
  output_file="${test_name}.output.yaml"
  log_file="${test_name}.log"

  test_start "${test_name}" "${input_file}"
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
    SUCCESS=1
  else
    test_passed "${test_name}"
  fi
done

cleanup_tests

exit $SUCCESS
