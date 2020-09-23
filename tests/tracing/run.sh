#!/usr/bin/env bash

test_start()        { echo -e "[.] $*"; }
test_passed()       { echo -e "[+] $*"; }
test_failed()       { echo -e "[-] $*"; }

SCRIPT_PATH="$( dirname $(realpath ${0}) )"

source "${SCRIPT_PATH}/../functions.sh"

get_variables "${SCRIPT_PATH}"
prepare_environment

SUCCESS=0
for input_file in ${INPUT_FILES}; do
  test_name=$(echo "${input_file}" | sed -e 's/.input.yaml$//g')
  output_file="${test_name}.output.yaml"

  sed "s/%CURRENT_CHART_VERSION%/${CURRENT_CHART_VERSION}/g" ${STATICS_PATH}/${output_file} > "${TMP_PATH}/${output_file}"

  test_start "${test_name}" ${input_file}
  docker run --rm \
    -v ${SCRIPT_PATH}/../../deploy/helm/sumologic:/chart \
    -v "${STATICS_PATH}/${input_file}":/values.yaml \
    sumologic/kubernetes-tools:master \
    helm template /chart -f /values.yaml \
      --namespace sumologic \
      --set sumologic.traces.enabled=true \
      --set sumologic.accessId='accessId' \
      --set sumologic.accessKey='accessKey' \
      -s templates/otelcol-configmap.yaml 2>/dev/null 1> "${OUT}"

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
