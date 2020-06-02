#!/usr/bin/bash

test_start()        { echo -e "[.] $*"; }
test_passed()       { echo -e "[+] $*"; }
test_failed()       { echo -e "[-] $*"; }

readonly SCRIPT_PATH="$( dirname $(realpath ${0}) )"
readonly STATICS_PATH="${SCRIPT_PATH}/static"
readonly INPUT_FILES="$(ls "${STATICS_PATH}" | grep input)"
readonly OUT="new_values.yaml"


for input_file in ${INPUT_FILES}; do
  test_name=$(echo "${input_file}" | sed -e 's/.input.yaml$//g')
  output_file="${test_name}.output.yaml"

  test_start "${test_name}" ${input_file}
  docker run --rm \
    -v ${SCRIPT_PATH}/../../deploy/helm/sumologic:/chart \
    -v "${STATICS_PATH}/${input_file}":/values.yaml \
    sumologic/kubernetes-tools:master \
    helm template /chart -f /values.yaml \
      --set sumologic.accessId='accessId' \
      --set sumologic.accessKey='accessKey' \
      -s templates/setup/setup-configmap.yaml 2>/dev/null 1> "${OUT}"

  test_output=$(diff "${STATICS_PATH}/${output_file}" "${OUT}")

  if [[ -n "${test_output}" ]]; then
    echo -e "\tOutput diff (${STATICS_PATH}/${output_file}):\n${test_output}"
    test_failed "${test_name}"
  else
    test_passed "${test_name}"
  fi

  rm "${OUT}"
done