#!/bin/bash

set -e

# Exemplar script output
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
readonly RECEIVER_MOCK_POD="$(kubectl get pod -n receiver-mock --no-headers -lapp=receiver-mock --output custom-columns=NAME:.metadata.name)"

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
        -- curl -s -g -XPOST collection-prometheus-oper-prometheus.sumologic.svc.cluster.local:9090/api/v1/query \
        --data-urlencode "query=container_memory_rss{job='kubelet',container='${container_name}'}" \
        | jq -r '.data.result[0].value[1]'
}

function ingested_metrics_count() {
    kubectl exec -n receiver-mock "${RECEIVER_MOCK_POD}" \ -- curl -s -XGET localhost:3000/metrics | \
        grep "^receiver_mock_metrics_count" | awk '{print $2}'
}

function reset_receiver_mock_metrics() {
    kubectl exec -n receiver-mock "${RECEIVER_MOCK_POD}" \
        -- curl -s -XPOST localhost:3000/metrics-reset >/dev/null
}

function run_test() {
    local duration_seconds="${1}"
    echo "Starting perf tests"

    if [[ $(is_avalanche_running) -eq 0 ]]; then
        echo "Avalanche is running, stop it, wait for the collection to cool down and then rerun the test"
        exit 1
    fi

    local PROMETHEUS_MEMORY_RSS_START
    local PROMETHEUS_MEMORY_RSS_FINISH
    local AVALANCHE_COUNT
    local AVALANCHE_POD_NAME

    PROMETHEUS_MEMORY_RSS_START=$(container_memory_rss prometheus)

    echo "Setting up avalanche..."
    kubectl apply --wait -f "${AVALANCHE_YAML_PATH}" >/dev/null || \
        (echo "Failed applying avalanche yaml (${AVALANCHE_YAML_PATH})" && exit 1)
    kubectl wait --timeout=120s -n avalanche --for=condition=Available deployment/avalanche >/dev/null

    AVALANCHE_COUNT="$(kubectl get deployment -n avalanche avalanche -o json | jq -r '.spec.replicas')"
    printf "Running %d avalanche(s) with the following arguments:\n" "${AVALANCHE_COUNT}"
    AVALANCHE_POD_NAME="$(kubectl get pods --no-headers -lapp=avalanche -n avalanche -o custom-columns=NAME:.metadata.name)"
    kubectl get pod "${AVALANCHE_POD_NAME}" -n avalanche -o json | jq -r '.spec.containers[0].args[]'
    echo

    echo "Letting prometheus ingest metrics for ${duration_seconds}s..."
    sleep "${duration_seconds}"
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
    echo "${0} <test_duration_in_seconds>"
}

readonly DURATION="${1}"
if [[ -z "${DURATION}" ]] ; then
    usage
    exit 1
fi

if ! grep -E "^[0-9]+$" <<< "${DURATION}" >/dev/null; then
    usage
    echo
    echo "Failed to parse duration \"${DURATION}\""
    exit 1
fi

reset_receiver_mock_metrics
run_test "${DURATION}"
readonly metric_count="$(ingested_metrics_count)"
printf "receiver-mock ingested %d metrics during the test\n" "${metric_count}"
