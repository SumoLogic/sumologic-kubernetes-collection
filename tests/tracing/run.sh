#!/usr/bin/env bash

SCRIPT_PATH="$( dirname $(realpath ${0}) )"

source "${SCRIPT_PATH}/../functions.sh"

get_variables "${SCRIPT_PATH}"
prepare_environment

SUCCESS=0
for input_file in ${INPUT_FILES}; do
  perform_test "${input_file}" "templates/otelcol-configmap.yaml" --set sumologic.traces.enabled=true
done

cleanup_environment

exit $SUCCESS
