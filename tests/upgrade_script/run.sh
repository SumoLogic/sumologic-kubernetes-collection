#!/usr/bin/bash

# Test generation:
# export test_name=example_test; \
# bash deploy/helm/sumologic/upgrade-1.0.0.sh \
#   tests/upgrade_script/static/${test_name}.input.yaml \
#   1> tests/upgrade_script/static/${test_name}.log 2>&1 \
# && cp new_values.yaml tests/upgrade_script/static/${test_name}.output.yaml

test_start()        { echo -e "[.] $*"; }
test_passed()       { echo -e "[+] $*"; }
test_failed()       { echo -e "[-] $*"; }

readonly SCRIPT_PATH="$( dirname $(realpath ${0}) )"
readonly STATICS_PATH="${SCRIPT_PATH}/static"
readonly INPUT_FILES="$(ls "${STATICS_PATH}" | grep input)"
readonly TMP_OUT="tmp_out.log"
readonly OUT="new_values.yaml"


for input_file in ${INPUT_FILES}; do
  test_name=$(echo "${input_file}" | grep -oP '^.*?(?=\.input\.yaml)')
  output_file="${test_name}.output.yaml"
  log_file="${test_name}.log"

  test_start "${test_name}"
  bash "${SCRIPT_PATH}/../../deploy/helm/sumologic/upgrade-1.0.0.sh" "${STATICS_PATH}/${input_file}" 1>"${TMP_OUT}" 2>&1

  test_output=$(diff "${STATICS_PATH}/${output_file}" "${OUT}")
  test_log=$(diff "${STATICS_PATH}/${log_file}" "${TMP_OUT}")

  if [[ -n "${test_output}" || -n "${test_log}" ]]; then
    if [[ -n "${test_output}" ]]; then
      echo -e "\tOutput diff:\n${test_output}"
    fi
    if [[ -n "${test_log}" ]]; then
      echo -e "\tLog diff:\n${test_log}"
    fi
    test_failed "${test_name}"
  else
    test_passed "${test_name}"
  fi

  rm "${TMP_OUT}" "${OUT}"
done