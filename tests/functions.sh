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

function get_variables() {
  SCRIPT_PATH="${1}"
  readonly STATICS_PATH="${SCRIPT_PATH}/static"
  readonly TMP_PATH="${SCRIPT_PATH}/tmp"
  readonly INPUT_FILES="$(ls "${STATICS_PATH}" | grep input)"
  readonly OUT="${TMP_PATH}/new_values.yaml"
  readonly CURRENT_CHART_VERSION=$(yq r ${SCRIPT_PATH}/../../deploy/helm/sumologic/Chart.yaml version)
}

function prepare_environment() {
  mkdir -p "${TMP_PATH}"

  rm -rf "${SCRIPT_PATH}/../../deploy/helm/sumologic/tmpcharts"
  docker run --rm \
    -v ${SCRIPT_PATH}/../../deploy/helm/sumologic:/chart \
    sumologic/kubernetes-tools:master \
    helm dependency update /chart
}

function cleanup_environment() {
  if [[ -n "${TMP_PATH}" ]]; then
    rm -rf "${TMP_PATH}"
  fi
}

function patch_test() {
  local input_file="${1}"
  local output_file="${2}"
  sed "s/%CURRENT_CHART_VERSION%/${CURRENT_CHART_VERSION}/g" "${input_file}" > "${output_file}"
}

function generate_file {
  local template_name="${1}"

  docker run --rm \
    -v ${SCRIPT_PATH}/../../deploy/helm/sumologic:/chart \
    -v "${STATICS_PATH}/${input_file}":/values.yaml \
    sumologic/kubernetes-tools:master \
    helm template /chart -f /values.yaml \
      --namespace sumologic \
      --set sumologic.accessId='accessId' \
      --set sumologic.accessKey='accessKey' \
      "${@:2}" \
      -s "${template_name}" 2>/dev/null 1> "${OUT}"
}

function perform_test {
  local input_file="${1}"
  local template_name="${2}"

  test_name=$(echo "${input_file}" | sed -e 's/.input.yaml$//g')
  output_file="${test_name}.output.yaml"

  patch_test "${STATICS_PATH}/${output_file}" "${TMP_PATH}/${output_file}"

  test_start "${test_name}" ${input_file}
  generate_file "${template_name}" "${@:3}"

  test_output=$(diff "${TMP_PATH}/${output_file}" "${OUT}" | cat -te)
  rm "${OUT}"

  if [[ -n "${test_output}" ]]; then
    echo -e "\tOutput diff (${STATICS_PATH}/${output_file}):\n${test_output}"
    test_failed "${test_name}"
    SUCCESS=1
  else
    test_passed "${test_name}"
  fi
}
