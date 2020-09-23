#!/bin/bash

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