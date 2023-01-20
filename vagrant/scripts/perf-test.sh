#!/bin/bash

set -euo pipefail

# Exemplar script output
# TEST_DURATION=300 TEST_WARMUP_DURATION=30 ./scripts/perf-test.sh
#
# Starting perf tests
# Setting up avalanche...
# Running 1 avalanche(s) with the following arguments:
# --metric-count=200
# --series-count=200
# --port=9006
# --series-interval=60000
# --metric-interval=60000
# --value-interval=30
#
# Letting cluster warmup for 10s...
# Resetting metrics count for receiver-mock-8659b9b57-x975t
# Letting prometheus ingest metrics for 20s...
# Cleaning up avalanche...
#
# Prometheus container memory RSS:
#         start:           657Mi
#         finish:         1200Mi
#         diff:            543Mi
# receiver-mock ingested 3575 metrics during the test

readonly DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
readonly AVALANCHE_YAML_PATH="${DIR}/../k8s/avalanche.yaml"
readonly RECEIVER_MOCK_PODS="$(kubectl get pod -n receiver-mock --no-headers -lapp=receiver-mock --output custom-columns=NAME:.metadata.name)"
readonly RECEIVER_MOCK_POD="$(kubectl get pod -n receiver-mock --no-headers -lapp=receiver-mock -o=jsonpath='{.items[0].metadata.name}')"
readonly PROMETHEUS_API_QUERY_URL="collection-prometheus-oper-prometheus.sumologic.svc.cluster.local.:9090/api/v1/query"

function is_avalanche_running() {
    local out
    out="$(kubectl get pods --no-headers -n avalanche --output custom-columns=NAME:.metadata.name)"
    if [[ -z "${out}" ]]; then
        echo 1
    else
        echo 0
    fi
}

function container_memory_rss() {
    local container_name="${1}"

    kubectl exec -n receiver-mock "${RECEIVER_MOCK_POD}" \
        -- curl -s -g -XPOST "${PROMETHEUS_API_QUERY_URL}" \
        --data-urlencode "query=container_memory_rss{job='kubelet',container='${container_name}'}" \
        | jq -r '.data.result[0].value[1]' # value[0] is the timestamp
}

function ingested_metrics_count() {
    kubectl exec -n receiver-mock "${RECEIVER_MOCK_POD}" \
        -- curl -s -g -XPOST "${PROMETHEUS_API_QUERY_URL}" \
        --data-urlencode "query=sum(receiver_mock_metrics_count)" \
        | jq -r '.data.result[0].value[1]' # value[0] is the timestamp
}

function reset_receiver_mock_metrics() {
    for pod in ${RECEIVER_MOCK_PODS}; do
        printf "Resetting metrics count for %s\n" "${pod}"
        kubectl exec -n receiver-mock "${pod}" \
            -- curl -s -XPOST localhost:3000/metrics-reset >/dev/null
    done
}

function run_test() {
    local WARMUP_DURATION_SECONDS="${1}"
    local DURATION_SECONDS="${2}"
    echo "Starting perf tests"

    IS_AVALANCHE_RUNNING="$(is_avalanche_running)"
    if [[ ${IS_AVALANCHE_RUNNING} -eq 0 ]]; then
        echo "Avalanche is running, stop it, wait for the collection to cool down and then rerun the test"
        exit 1
    fi

    local PROMETHEUS_MEMORY_RSS_START
    local PROMETHEUS_MEMORY_RSS_FINISH
    local AVALANCHE_COUNT
    local AVALANCHE_POD_NAME

    echo "Setting up avalanche..."
    kubectl apply --wait -f "${AVALANCHE_YAML_PATH}" >/dev/null || \
        (echo "Failed applying avalanche yaml (${AVALANCHE_YAML_PATH})" && exit 1)
    kubectl wait --timeout=120s -n avalanche --for=condition=Available deployment/avalanche >/dev/null

    AVALANCHE_COUNT="$(kubectl get deployment -n avalanche avalanche -o json | jq -r '.spec.replicas')"
    printf "Running %d avalanche(s) with the following arguments:\n" "${AVALANCHE_COUNT}"
    AVALANCHE_POD_NAME="$(kubectl get pods --no-headers -lapp=avalanche -n avalanche -o custom-columns=NAME:.metadata.name)"
    kubectl get pod "${AVALANCHE_POD_NAME}" -n avalanche -o json | jq -r '.spec.containers[0].args[]'
    echo

    echo "Letting cluster warmup for ${WARMUP_DURATION_SECONDS}s..."
    sleep "${WARMUP_DURATION_SECONDS}"

    reset_receiver_mock_metrics
    PROMETHEUS_MEMORY_RSS_START=$(container_memory_rss prometheus)
    echo "Letting prometheus ingest metrics for ${DURATION_SECONDS}s..."
    sleep "${DURATION_SECONDS}"
    PROMETHEUS_MEMORY_RSS_FINISH=$(container_memory_rss prometheus)

    echo "Cleaning up avalanche..."
    kubectl delete -f "${AVALANCHE_YAML_PATH}" >/dev/null ||
        (echo "Failed deleting avalanche yaml (${AVALANCHE_YAML_PATH})" && exit 1)

    printf "\n"
    printf "Prometheus container memory RSS:\n"
    printf "\tstart:\t%12dMi\n" "$(( PROMETHEUS_MEMORY_RSS_START / 1024 / 1024 ))"
    printf "\tfinish:\t%12dMi\n" "$(( PROMETHEUS_MEMORY_RSS_FINISH / 1024 / 1024 ))"
    printf "\tdiff:\t%12dMi\n" "$(( ("${PROMETHEUS_MEMORY_RSS_FINISH} - ${PROMETHEUS_MEMORY_RSS_START}") / 1024 / 1024 ))"
}

function usage() {
    echo "Usage:"
    echo "TEST_DURATION=<duration_in_seconds> TEST_WARMUP_DURATION=<warmup_in_seconds> ${0}"
}

function check_duration_variable() {
    local VARIABLE_NAME="${1}"
    if [[ -z "${!VARIABLE_NAME}" ]] ; then
        usage
        exit 1
    fi
    if ! grep -E "^[0-9]+$" <<< "${!VARIABLE_NAME}" >/dev/null; then
        usage
        echo
        echo "Failed to parse duration \"${!VARIABLE_NAME}\""
        exit 1
    fi
}

readonly TEST_DURATION="${TEST_DURATION}"
readonly TEST_WARMUP_DURATION="${TEST_WARMUP_DURATION}"
check_duration_variable TEST_DURATION
check_duration_variable TEST_WARMUP_DURATION

run_test "${TEST_WARMUP_DURATION}" "${TEST_DURATION}"
readonly metric_count="$(ingested_metrics_count)"
printf "receiver-mock ingested %d metrics during the test\n" "${metric_count}"
