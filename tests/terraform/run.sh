#!/usr/bin/env bash

SCRIPT_PATH="$( dirname $(realpath ${0}) )"

source "${SCRIPT_PATH}/../functions.sh"

get_variables "${SCRIPT_PATH}"
prepare_environment

SUCCESS=0
for input_file in ${INPUT_FILES}; do
  perform_test "${input_file}" "templates/setup/setup-configmap.yaml"
done

cleanup_environment
exit $SUCCESS
