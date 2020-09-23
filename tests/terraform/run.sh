#!/usr/bin/env bash

SCRIPT_PATH="$( dirname $(realpath ${0}) )"

source "${SCRIPT_PATH}/../functions.sh"

get_variables "${SCRIPT_PATH}"
prepare_environment

SUCCESS=0
for input_file in ${INPUT_FILES}; do
  test_name=$(echo "${input_file}" | sed -e 's/.input.yaml$//g')
  output_file="${test_name}.output.yaml"

  patch_test "${STATICS_PATH}/${output_file}" "${TMP_PATH}/${output_file}"

  test_start "${test_name}" ${input_file}
  generate_file "templates/setup/setup-configmap.yaml"

  test_output=$(diff "${TMP_PATH}/${output_file}" "${OUT}" | cat -te)
  rm "${OUT}"

  if [[ -n "${test_output}" ]]; then
    echo -e "\tOutput diff (${STATICS_PATH}/${output_file}):\n${test_output}"
    test_failed "${test_name}"
    SUCCESS=1
  else
    test_passed "${test_name}"
  fi
done

cleanup_environment
exit $SUCCESS
