#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly NAMESPACE="${1:-}"
readonly PVC_SELECTOR="${2:-}"
readonly HPA_NAME="${3:-}"
readonly ARGS_NUMBER="$#"
readonly MIN_ARGS_NUMBER=2
readonly MAX_ARGS_NUMBER=3

function print_help() {
  echo "This script removes the unmounted PVCs with given selector."
  echo "By default it removes all of the found unmounted PVCs."
  echo "With HPA-name argument provided it removes the PVCs which belongs to statefulset pod instances with equal or higher number than the current or desired HPA replicas (the higher value of those two is used)."
  echo
  echo "Usage:"
  echo "  pvc-cleaner namespace PVC-selector [HPA-name]"
}

# Disable 'Command appears to be unreachable.' as it is invoked in trap
# shellcheck disable=SC2317
function err_report() {
  if [[ "${1}" != "0" ]]; then
    echo
    echo "Caught error with code ${1} on line ${2}."
    echo "The unmounted PVCs deletion has failed."
  fi
}
trap 'err_report $? $LINENO' EXIT

function delete_all() {
  if [[ ${ARGS_NUMBER} -eq ${MIN_ARGS_NUMBER} ]]; then
    return 0
  else
    return 1
  fi
}

function test_kubectl_connection() {
  kubectl -n "${NAMESPACE}" get pvc --no-headers > /dev/null

  return $?
}

function check_hpa_exists() {
  kubectl -n "${NAMESPACE}" get hpa "${HPA_NAME}" > /dev/null

  return $?
}

function get_sorted_pvcs() {
  kubectl -n "${NAMESPACE}" get pvc --selector="${PVC_SELECTOR}" --no-headers \
    | awk '{print $1}' \
    | sort -V
}

function get_pvcs_count() {
  kubectl -n "${NAMESPACE}" get pvc --selector="${PVC_SELECTOR}" --no-headers \
    | wc -l
}

function check_pvc_amount() {
  local pvc_amount="$1"
  if [[ ${pvc_amount} -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

function max_number() {
  local num1
  local num2

  num1="${1}"
  num2="${2}"

  if [[ ${num1} -gt ${num2} ]]; then
    echo "${num1}"
  else
    echo "${num2}"
  fi
}

function check_if_pvc_unmounted() {
  local pvc_name="${1}"

  kubectl -n "${NAMESPACE}" describe pvc "${pvc_name}" \
    | grep "^Used By:" \
    | grep -q "<none>"

  return $?
}

function get_pvc_number() {
  local pvc_name="${1}"

  # strip the pvc number from the end of the name, after the last dash -
  echo "${pvc_name##*-}"
}

function check_args() {
  if [[ $# -lt ${MIN_ARGS_NUMBER} ]] || [[ $# -gt ${MAX_ARGS_NUMBER} ]]; then
    return 1
  fi
}

function get_replicas_to_keep() {
  local current_replicas desired_replicas
  current_replicas="$(kubectl -n "${NAMESPACE}" get hpa "${HPA_NAME}" -o jsonpath='{.status.currentReplicas}')"
  desired_replicas="$(kubectl -n "${NAMESPACE}" get hpa "${HPA_NAME}" -o jsonpath='{.status.desiredReplicas}')"

  max_number "${desired_replicas}" "${current_replicas}"
}

# shellcheck disable=SC2310
if ! check_args "$@"; then
  print_help
  exit 0
fi

# shellcheck disable=SC2310
if ! test_kubectl_connection; then
  echo "The kubectl command could not list PVCs, please check the connection."
  exit 1
fi

# shellcheck disable=SC2310
if ! delete_all && ! check_hpa_exists; then
  echo "Provided HPA ${HPA_NAME} not found."
  exit 1
fi

PVC_LIST="$(get_sorted_pvcs)"
PVC_AMOUNT="$(get_pvcs_count)"

readonly PVC_LIST PVC_AMOUNT

# shellcheck disable=SC2310
if check_pvc_amount "${PVC_AMOUNT}"; then
  echo "Found ${PVC_AMOUNT} PVC instances in the '${NAMESPACE}' namespace with '${PVC_SELECTOR}' selector."
  echo
else
  echo "Did not found any PVC instances in the '${NAMESPACE}' namespace with '${PVC_SELECTOR}' selector. Exiting."
  exit 1
fi

# shellcheck disable=SC2310
if delete_all; then
  KEEP_REPLICAS=""
  echo "Preparing for deletion of all the unmounted PVCs."
  echo
else
  KEEP_REPLICAS="$(get_replicas_to_keep)"
  echo "Going to use the '${HPA_NAME}' HPA for the wanted replica count."
  echo "Preparing for deletion PVCs which belong to ${PVC_SELECTOR} and are equal or higher than ${KEEP_REPLICAS}"
  echo
fi
readonly KEEP_REPLICAS

for pvc in ${PVC_LIST}; do
  pvc_number="$(get_pvc_number "${pvc}")"
  # shellcheck disable=SC2310
  if ! delete_all && [[ "${pvc_number}" -lt ${KEEP_REPLICAS} ]]; then
    echo "Skipping pvc: ${pvc}"
    continue
  fi

  # shellcheck disable=SC2310
  if check_if_pvc_unmounted "${pvc}"; then
    echo "Deleting the unmounted pvc: ${pvc}"
    kubectl --namespace "${NAMESPACE}" delete pvc "${pvc}"
  else
    echo "The ${pvc} pvc is mounted, skipping."
  fi
done

echo "All of the PVCs have been processed. Exiting."
exit 0
