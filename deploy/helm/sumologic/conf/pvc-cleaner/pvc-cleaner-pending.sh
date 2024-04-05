#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly NAMESPACE="${1:-}"
readonly POD_SELECTOR="${2:-}"
readonly ARGS_NUMBER="$#"
readonly MIN_ARGS_NUMBER=2
readonly MAX_ARGS_NUMBER=2

function print_help() {
  echo "This script removes the PVCs which cannot be bound due to Zone mismatch."
  echo "  pvc-cleaner namespace POD-selector"
}

# Disable 'Command appears to be unreachable.' as it is invoked in trap
# shellcheck disable=SC2317
function err_report() {
  if [[ "${1}" != "0" ]]; then
    echo
    echo "Caught error with code ${1} on line ${2}."
    echo "The PVCs deletion has failed."
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
  kubectl -n "${NAMESPACE}" get pod --no-headers > /dev/null

  return $?
}

function get_sorted_pods() {
  (kubectl -n "${NAMESPACE}" get pod --selector="${POD_SELECTOR}" --no-headers \
    | grep Pending || true) \
    | awk '{print $1}' \
    | sort -V
}

function get_pods_count() {
  get_sorted_pods \
    | wc -l
}

function check_pod_amount() {
  local pod_amount="$1"
  if [[ ${pod_amount} -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

function check_if_pod_has_zone_issue() {
  local pod_name="${1}"

  kubectl -n "${NAMESPACE}" describe pod "${pod_name}" \
    | tail -n 2 \
    | grep -q "volume node affinity conflict"

  return $?
}

function get_pvc_names() {
  local pod_name="${1}"

  kubectl -n "${NAMESPACE}" get pvc \
    | grep ${pod_name} \
    | awk '{print $1}'
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

# shellcheck disable=SC2310
if ! check_args "$@"; then
  print_help
  exit 0
fi

# shellcheck disable=SC2310
if ! test_kubectl_connection; then
  echo "The kubectl command could not list PODs, please check the connection."
  exit 1
fi

POD_LIST="$(get_sorted_pods)"
POD_AMOUNT="$(get_pods_count)"

readonly POD_LIST POD_AMOUNT

# shellcheck disable=SC2310
if check_pod_amount "${POD_AMOUNT}"; then
  echo "Found ${POD_AMOUNT} Pod instances in the '${NAMESPACE}' namespace with '${POD_SELECTOR}' selector."
  echo
else
  echo "Did not found any Pending Pod instances in the '${NAMESPACE}' namespace with '${POD_SELECTOR}' selector. Exiting."
  exit 0
fi

# shellcheck disable=SC2310
if delete_all; then
  echo "Preparing for deletion PVCs which belong to ${POD_SELECTOR} Pods"
  echo
fi

for pod in ${POD_LIST}; do
  # shellcheck disable=SC2310
  echo "pod:${pod}:dop"
  if check_if_pod_has_zone_issue "${pod}"; then
    pvcs="$(get_pvc_names "${pod}")"
    for pvc in "${pvcs}"; do
      echo "Deleting the pvc: ${pvc}"
      kubectl --namespace "${NAMESPACE}" delete pvc "${pvc}" --wait=false
    done
  else
    echo "The ${pod} pod seems to be pending because of other reason, skipping."
  fi
done

echo "All of the PODs have been processed. Exiting."
exit 0
