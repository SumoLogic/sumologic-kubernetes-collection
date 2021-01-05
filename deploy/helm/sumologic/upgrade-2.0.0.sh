#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

readonly OLD_VALUES_YAML="${1:---help}"
readonly PREVIOUS_VERSION=1.3

readonly TEMP_FILE=upgrade-2.0.0-temp-file

readonly MIN_BASH_VERSION=4.0
readonly MIN_YQ_VERSION=3.4.0
readonly MAX_YQ_VERSION=4.0.0

readonly KEY_MAPPINGS="
prometheus-operator.prometheusOperator.tlsProxy.enabled:kube-prometheus-stack.prometheusOperator.tls.enabled
otelcol.deployment.image.name:otelcol.deployment.image.repository
"

readonly KEY_VALUE_MAPPINGS="
"

readonly KEY_MAPPINGS_MULTIPLE="
image.repository:fluentd.image.repository:sumologic.setup.job.image.repository
image.tag:fluentd.image.tag:sumologic.setup.job.image.tag
image.pullPolicy:fluentd.image.pullPolicy:sumologic.setup.job.image.pullPolicy
"

readonly KEYS_TO_DELETE="
prometheus-operator
"

# https://slides.com/perk/how-to-train-your-bash#/41
readonly LOG_FILE="/tmp/$(basename "$0").log"
info()    { echo -e "[INFO]    $*" | tee -a "${LOG_FILE}" >&2 ; }
warning() { echo -e "[WARNING] $*" | tee -a "${LOG_FILE}" >&2 ; }
error()   { echo -e "[ERROR]   $*" | tee -a "${LOG_FILE}" >&2 ; }
fatal()   { echo -e "[FATAL]   $*" | tee -a "${LOG_FILE}" >&2 ; exit 1 ; }

function print_help_and_exit() {
  local MAN
  set +e
  read -r -d '' MAN <<EOF
Thank you for upgrading to v2.0.0 of the Sumo Logic Kubernetes Collection Helm chart.
As part of this major release, the format of the values.yaml file has changed.

This script will automatically take the configurations of your existing values.yaml
and return one that is compatible with v2.0.0.

Requirements:
  yq (${MAX_YQ_VERSION} > x >= ${MIN_YQ_VERSION}) https://github.com/mikefarah/yq/releases/tag/${MIN_YQ_VERSION}
  grep
  sed
  bash (>= ${MIN_BASH_VERSION})

Usage:
  # for default helm release name 'collection' and namespace 'sumologic'
  ./upgrade-2.0.0.sh /path/to/values.yaml

  # for non-default helm release name and k8s namespace
  ./upgrade-2.0.0.sh /path/to/values.yaml helm_release_name k8s_namespace

Returns:
  new_values.yaml

For more details, please refer to Migration steps and Changelog here:
#TODO fix link
https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v1.0/deploy/docs/v2_migration_doc.md
EOF
  set -e

  echo "${MAN}"
  exit 0
}

function check_if_print_help_and_exit() {
  if [[ "$1" == "--help" ]]; then
    print_help_and_exit
  fi
}

function check_required_command() {
  local command_to_check="$1"
  command -v "${command_to_check}" >/dev/null 2>&1 || { error "Required command is missing: ${command_to_check}"; fatal "Please consult --help and install missing commands before continue. Aborting."; }
}

function compare_versions() {
  local no_lower_than="${1}"
  local app_version="${2}"

  if [[ "$(printf '%s\n' "${app_version}" "${no_lower_than}" | sort -V | head -n 1)" == "${no_lower_than}" ]]; then
    echo "pass"
  else
    echo "fail"
  fi
}

function check_app_version() {
  local app_name="${1}"
  local no_lower_than="${2}"
  local app_version="${3}"

  if [[ -z ${app_version} ]] || [[ $(compare_versions "${no_lower_than}" "${app_version}") == "fail" ]]; then
    error "${app_name} version: '${app_version}' is invalid - it should be no lower than ${no_lower_than}"
    fatal "Please update your ${app_name} and retry."
  fi
}

function check_app_version_with_max() {
  local app_name="${1}"
  local no_lower_than="${2}"
  local lower_than="${3}"
  local app_version="${4}"

  if [[ -z ${app_version} ]] || [[ $(compare_versions "${no_lower_than}" "${app_version}") == "fail" ]]; then
    error "${app_name} version: '${app_version}' is invalid - it should be no lower than ${no_lower_than}"
    fatal "Please update your ${app_name} and retry."
  fi

  if [[ "${app_version}" == "${lower_than}" ]] || [[ $(compare_versions "${app_version}" "${lower_than}") == "fail" ]]; then
    error "${app_name} version: '${app_version}' is invalid - it should be lower than ${lower_than}"
    fatal "Please downgrade '${app_name}' and retry."
  fi
}

function check_yq_version() {
  local yq_version
  readonly yq_version=$(yq --version | grep -oE '[^[:space:]]+$')

  check_app_version_with_max "yq" "${MIN_YQ_VERSION}" "${MAX_YQ_VERSION}" "${yq_version}"
}

function check_bash_version() {
  check_app_version "bash" "${MIN_BASH_VERSION}" "${BASH_VERSION}"
}

function create_temp_file() {
  echo -n > "${TEMP_FILE}"
}

function migrate_prometheus_operator_to_kube_prometheus_stack() {
  # Nothing to migrate, return
  if [[ -z $(yq r "${TEMP_FILE}" prometheus-operator) ]] ; then
    return
  fi

  info "Migrating prometheus-config-reloader container to config-reloader in prometheusSpec"
  yq m -i --arrays append \
    "${TEMP_FILE}" \
    <(
      yq p <(
        yq w <(
          yq r "${TEMP_FILE}" -- 'prometheus-operator.prometheus.prometheusSpec.containers.(name==prometheus-config-reloader)' \
          ) name config-reloader \
        ) 'prometheus-operator.prometheus.prometheusSpec.containers[+]'
      )
  yq d -i "${TEMP_FILE}" "prometheus-operator.prometheus.prometheusSpec.containers.(name==prometheus-config-reloader)"

  info "Migrating from prometheus-operator to kube-prometheus-stack"
  yq m -i \
    "${TEMP_FILE}" \
    <(
      yq p \
      <(yq r "${TEMP_FILE}" "prometheus-operator") \
      "kube-prometheus-stack" \
    )
  yq d -i "${TEMP_FILE}" "prometheus-operator"
}

function migrate_prometheus_recording_rules() {
  if [[ -z "$(yq r "${TEMP_FILE}" -- 'prometheus-operator')" ]]; then
    return
  fi

  local RECORDING_RULES_OVERRIDE
  RECORDING_RULES_OVERRIDE=$(yq r "${TEMP_FILE}" -- 'prometheus-operator.kubeTargetVersionOverride')

  if [[ "${RECORDING_RULES_OVERRIDE}" == "1.13.0-0" ]]; then
    info "Removing prometheus kubeTargetVersionOverride='1.13.0-0'"
    yq d -i "${TEMP_FILE}" "prometheus-operator.kubeTargetVersionOverride"
    add_prometheus_pre_1_14_recording_rules "${TEMP_FILE}"
  elif [[ -z "${RECORDING_RULES_OVERRIDE}" ]]; then
    add_prometheus_pre_1_14_recording_rules "${TEMP_FILE}"
  else
    warning "prometheus-operator.kubeTargetVersionOverride should be unset or set to '1.13.0-0'"
    warning "Actually it's set to: ${RECORDING_RULES_OVERRIDE}"
    warning "Please unset it or set it to '1.13.0-0' and rerun this script"
  fi
}

function kube_prometheus_stack_update_remote_write_regexes() {
  local URL_METRICS_OPERATOR_RULE
  # shellcheck disable=SC2016
  readonly URL_METRICS_OPERATOR_RULE='http://$(FLUENTD_METRICS_SVC).$(NAMESPACE).svc.cluster.local:9888/prometheus.metrics.operator.rule'

  local PROMETHEUS_METRICS_OPERATOR_RULE_REGEX
  readonly PROMETHEUS_METRICS_OPERATOR_RULE_REGEX="cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:"

  local TEMP_REWRITE_PROMETHEUS_METRICS_OPERATOR_RULE
  readonly TEMP_REWRITE_PROMETHEUS_METRICS_OPERATOR_RULE="$(
    yq r "${TEMP_FILE}" \
      "kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.\"url==${URL_METRICS_OPERATOR_RULE}\""
  )"

  local CURRENT_METRICS_OPERATOR_RULE_REGEX
  readonly CURRENT_METRICS_OPERATOR_RULE_REGEX="$(
    yq r "${TEMP_FILE}" \
    "kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.\"url==${URL_METRICS_OPERATOR_RULE}\".writeRelabelConfigs[0].regex"
  )"
  if [[ -n "${CURRENT_METRICS_OPERATOR_RULE_REGEX}" ]]; then
    if [[ -n $(diff <(echo "${PROMETHEUS_METRICS_OPERATOR_RULE_REGEX}") <(echo "${CURRENT_METRICS_OPERATOR_RULE_REGEX}")) ]] ; then
      info "Updating prometheus regex in rewrite rule for url: ${URL_METRICS_OPERATOR_RULE} but it has a different value than expected"
      info "Actual: '${CURRENT_METRICS_OPERATOR_RULE_REGEX}'"
      info "Expected: '${PROMETHEUS_METRICS_OPERATOR_RULE_REGEX}'"
    fi
  fi

  if [[ -n "${TEMP_REWRITE_PROMETHEUS_METRICS_OPERATOR_RULE}" ]]; then
    info "Updating prometheus regex in rewrite rule for url: ${URL_METRICS_OPERATOR_RULE}..."
    # shellcheck disable=SC2016
    yq delete -i "${TEMP_FILE}" 'kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite."url==http://$(FLUENTD_METRICS_SVC).$(NAMESPACE).svc.cluster.local:9888/prometheus.metrics.operator.rule"'

    local SCRIPT
    SCRIPT="$(cat <<- EOF
	- command: update
	  path: 'kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.[+]'
	  value:
	    url: ${URL_METRICS_OPERATOR_RULE}
	    writeRelabelConfigs:
	      - action: keep
	        regex: 'cluster_quantile:apiserver_request_duration_seconds:histogram_quantile|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile|cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:'
	        sourceLabels: [__name__]
	EOF
)"

    yq w -i "${TEMP_FILE}" --script <(echo "${SCRIPT}")
  fi

  ##############################################################################

  local URL_METRICS_CONTROL_PLANE_COREDNS
# shellcheck disable=SC2016
  readonly URL_METRICS_CONTROL_PLANE_COREDNS='http://$(FLUENTD_METRICS_SVC).$(NAMESPACE).svc.cluster.local:9888/prometheus.metrics.control-plane.coredns'

  local PROMETHEUS_METRICS_CONTROL_PLANE_COREDNS_REGEX
  readonly PROMETHEUS_METRICS_CONTROL_PLANE_COREDNS_REGEX="coredns;(?:coredns_cache_(size|(hits|misses)_total)|coredns_dns_request_duration_seconds_(count|sum)|coredns_(dns_request|dns_response_rcode|forward_request)_count_total|process_(cpu_seconds_total|open_fds|resident_memory_bytes))"

  local TEMP_REWRITE_PROMETHEUS_METRICS_CONTROL_PLANE_COREDNS
  readonly TEMP_REWRITE_PROMETHEUS_METRICS_CONTROL_PLANE_COREDNS="$(
    yq r "${TEMP_FILE}" \
      "kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.\"url==${URL_METRICS_CONTROL_PLANE_COREDNS}\""
  )"

  local CURRENT_METRICS_CONTROL_PLANE_COREDNS_REGEX
  readonly CURRENT_METRICS_CONTROL_PLANE_COREDNS_REGEX="$(
    yq r "${TEMP_FILE}" \
    "kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.\"url==${URL_METRICS_CONTROL_PLANE_COREDNS}\".writeRelabelConfigs[0].regex"
  )"
  if [[ -n "${CURRENT_METRICS_CONTROL_PLANE_COREDNS_REGEX}" ]] ; then
    if [[ -n $(diff <(echo "${PROMETHEUS_METRICS_CONTROL_PLANE_COREDNS_REGEX}") <(echo "${CURRENT_METRICS_CONTROL_PLANE_COREDNS_REGEX}")) ]] ; then
      info "Updating prometheus regex in rewrite rule for url: ${URL_METRICS_CONTROL_PLANE_COREDNS} but it has a different value than expected"
      info "Actual: '${CURRENT_METRICS_CONTROL_PLANE_COREDNS_REGEX}'"
      info "Expected: '${PROMETHEUS_METRICS_CONTROL_PLANE_COREDNS_REGEX}'"
    fi
  fi

  if [[ -n "${TEMP_REWRITE_PROMETHEUS_METRICS_CONTROL_PLANE_COREDNS}" ]]; then
    info "Updating prometheus regex in rewrite rule for url: ${URL_METRICS_CONTROL_PLANE_COREDNS}..."
    yq delete -i "${TEMP_FILE}" "kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.\"url==${URL_METRICS_CONTROL_PLANE_COREDNS}\""

    local SCRIPT
    SCRIPT="$(cat <<- EOF
	- command: update
	  path: 'kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.[+]'
	  value:
	    url: ${URL_METRICS_CONTROL_PLANE_COREDNS}
	    writeRelabelConfigs:
	      - action: keep
	        regex: 'coredns;(?:coredns_cache_(size|entries|(hits|misses)_total)|coredns_dns_request_duration_seconds_(count|sum)|coredns_(dns_request|dns_response_rcode|forward_request)_count_total|coredns_(forward_requests|dns_requests|dns_responses)_total|process_(cpu_seconds_total|open_fds|resident_memory_bytes))'
	        sourceLabels: [job, __name__]
	EOF
)"

    yq w -i "${TEMP_FILE}" --script <(echo "${SCRIPT}")
  fi
}

function kube_prometheus_stack_migrate_remote_write_urls() {
  info "Migrating prometheus remote write urls"

  # shellcheck disable=SC2016
  sed -i'.bak' \
    's#http://$(CHART).$(NAMESPACE).svc.cluster.local:9888/prometheus#http://$(FLUENTD_METRICS_SVC).$(NAMESPACE).svc.cluster.local:9888/prometheus#g' \
    "${TEMP_FILE}" && \
  rm "${TEMP_FILE}".bak
}

function kube_prometheus_stack_migrate_chart_env_variable() {
  if [[ -z "$(yq r "${TEMP_FILE}" -- 'kube-prometheus-stack.prometheus.prometheusSpec.containers.(name==config-reloader).env.(name==CHART)')" ]]; then
    return
  fi

  yq w -i "${TEMP_FILE}" \
    'kube-prometheus-stack.prometheus.prometheusSpec.containers.(name==config-reloader).env.(name==CHART).name' \
    FLUENTD_METRICS_SVC
}

function add_prometheus_pre_1_14_recording_rules() {
  local temp_file="${1}"
  local PROMETHEUS_RULES
  # Using tags below for heredoc
	PROMETHEUS_RULES=$(cat <<- "EOF"
	    groups:
	      - name: node-pre-1.14.rules
	        rules:
	          - expr: 1 - avg(rate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[1m]))
	            record: :node_cpu_utilisation:avg1m
	          - expr: |-
	              1 - avg by (node) (
	                rate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[1m])
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:)
	            record: node:node_cpu_utilisation:avg1m
	          - expr: |-
	              1 -
	              sum(
	                node_memory_MemFree_bytes{job="node-exporter"} +
	                node_memory_Cached_bytes{job="node-exporter"} +
	                node_memory_Buffers_bytes{job="node-exporter"}
	              )
	              /
	              sum(node_memory_MemTotal_bytes{job="node-exporter"})
	            record: ':node_memory_utilisation:'
	          - expr: |-
	              (node:node_memory_bytes_total:sum - node:node_memory_bytes_available:sum)
	              /
	              node:node_memory_bytes_total:sum
	            record: node:node_memory_utilisation:ratio
	          - expr: |-
	              1 -
	              sum by (node) (
	                (
	                  node_memory_MemFree_bytes{job="node-exporter"} +
	                  node_memory_Cached_bytes{job="node-exporter"} +
	                  node_memory_Buffers_bytes{job="node-exporter"}
	                )
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	              /
	              sum by (node) (
	                node_memory_MemTotal_bytes{job="node-exporter"}
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	            record: 'node:node_memory_utilisation:'
	          - expr: 1 - (node:node_memory_bytes_available:sum / node:node_memory_bytes_total:sum)
	            record: 'node:node_memory_utilisation_2:'
	          - expr: |-
	              max by (instance, namespace, pod, device) ((node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
	              - node_filesystem_avail_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
	              / node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
	            record: 'node:node_filesystem_usage:'
	          - expr: |-
	              sum by (node) (
	                node_memory_MemTotal_bytes{job="node-exporter"}
	                * on (namespace, pod) group_left(node)
	                  node_namespace_pod:kube_pod_info:
	              )
	            record: node:node_memory_bytes_total:sum
	          - expr: |-
	              sum(irate(node_network_receive_bytes_total{job="node-exporter",device!~"veth.+"}[1m])) +
	              sum(irate(node_network_transmit_bytes_total{job="node-exporter",device!~"veth.+"}[1m]))
	            record: :node_net_utilisation:sum_irate
	          - expr: |-
	              sum by (node) (
	                (irate(node_network_receive_bytes_total{job="node-exporter",device!~"veth.+"}[1m]) +
	                irate(node_network_transmit_bytes_total{job="node-exporter",device!~"veth.+"}[1m]))
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	            record: node:node_net_utilisation:sum_irate
	          - expr: |-
	              sum(irate(node_network_receive_drop_total{job="node-exporter",device!~"veth.+"}[1m])) +
	              sum(irate(node_network_transmit_drop_total{job="node-exporter",device!~"veth.+"}[1m]))
	            record: :node_net_saturation:sum_irate
	          - expr: |-
	              sum by (node) (
	                (irate(node_network_receive_drop_total{job="node-exporter",device!~"veth.+"}[1m]) +
	                irate(node_network_transmit_drop_total{job="node-exporter",device!~"veth.+"}[1m]))
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	            record: node:node_net_saturation:sum_irate
	          - expr: |-
	              max by (instance, namespace, pod, device) ((node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
	              - node_filesystem_avail_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
	              / node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
	            record: 'node:node_filesystem_usage:'
	          - expr: |-
	              sum(node_load1{job="node-exporter"})
	              /
	              sum(node:node_num_cpu:sum)
	            record: ':node_cpu_saturation_load1:'
	          - expr: |-
	              sum by (node) (
	                node_load1{job="node-exporter"}
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	              /
	              node:node_num_cpu:sum
	            record: 'node:node_cpu_saturation_load1:'
	          - expr: avg(irate(node_disk_io_time_weighted_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m]))
	            record: :node_disk_saturation:avg_irate
	          - expr: |-
	              avg by (node) (
	                irate(node_disk_io_time_weighted_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m])
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	            record: node:node_disk_saturation:avg_irate
	          - expr: avg(irate(node_disk_io_time_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m]))
	            record: :node_disk_utilisation:avg_irate
	          - expr: |-
	              avg by (node) (
	                irate(node_disk_io_time_seconds_total{job="node-exporter",device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+"}[1m])
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	            record: node:node_disk_utilisation:avg_irate
	          - expr: |-
	              1e3 * sum(
	                (rate(node_vmstat_pgpgin{job="node-exporter"}[1m])
	              + rate(node_vmstat_pgpgout{job="node-exporter"}[1m]))
	              )
	            record: :node_memory_swap_io_bytes:sum_rate
	          - expr: |-
	              1e3 * sum by (node) (
	                (rate(node_vmstat_pgpgin{job="node-exporter"}[1m])
	              + rate(node_vmstat_pgpgout{job="node-exporter"}[1m]))
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	            record: node:node_memory_swap_io_bytes:sum_rate
	          - expr: |-
	              node:node_cpu_utilisation:avg1m
	                *
	              node:node_num_cpu:sum
	                /
	              scalar(sum(node:node_num_cpu:sum))
	            record: node:cluster_cpu_utilisation:ratio
	          - expr: |-
	              (node:node_memory_bytes_total:sum - node:node_memory_bytes_available:sum)
	              /
	              scalar(sum(node:node_memory_bytes_total:sum))
	            record: node:cluster_memory_utilisation:ratio
	          - expr: |-
	              sum by (node) (
	                node_load1{job="node-exporter"}
	              * on (namespace, pod) group_left(node)
	                node_namespace_pod:kube_pod_info:
	              )
	              /
	              node:node_num_cpu:sum
	            record: 'node:node_cpu_saturation_load1:'
	          - expr: |-
	              max by (instance, namespace, pod, device) (
	                node_filesystem_avail_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
	                /
	                node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
	                )
	            record: 'node:node_filesystem_avail:'
	          - expr: |-
	              max by (instance, namespace, pod, device) ((node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"}
	              - node_filesystem_avail_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
	              / node_filesystem_size_bytes{fstype=~"ext[234]|btrfs|xfs|zfs"})
	            record: 'node:node_filesystem_usage:'
	          - expr: |-
	              max(
	                max(
	                  kube_pod_info{job="kube-state-metrics", host_ip!=""}
	                ) by (node, host_ip)
	                * on (host_ip) group_right (node)
	                label_replace(
	                  (
	                    max(node_filesystem_files{job="node-exporter", mountpoint="/"})
	                    by (instance)
	                  ), "host_ip", "$1", "instance", "(.*):.*"
	                )
	              ) by (node)
	            record: 'node:node_inodes_total:'
	          - expr: |-
	              max(
	                max(
	                  kube_pod_info{job="kube-state-metrics", host_ip!=""}
	                ) by (node, host_ip)
	                * on (host_ip) group_right (node)
	                label_replace(
	                  (
	                    max(node_filesystem_files_free{job="node-exporter", mountpoint="/"})
	                    by (instance)
	                  ), "host_ip", "$1", "instance", "(.*):.*"
	                )
	              ) by (node)
	            record: 'node:node_inodes_free:'
	EOF
)

  yq w -i "${temp_file}" 'prometheus-operator.additionalPrometheusRulesMap."pre-1.14-node-rules"' \
    --from <(echo "${PROMETHEUS_RULES}")
}

function add_new_scrape_labels_to_prometheus_service_monitors(){
  if [[ -z "$(yq r "${TEMP_FILE}" -- 'prometheus-operator.prometheus.additionalServiceMonitors')" ]]; then
    return
  fi

  info "Adding 'sumologic.com/scrape: \"true\"' scrape labels to prometheus service monitors"
  yq w --style double -i "${TEMP_FILE}" \
    'prometheus-operator.prometheus.additionalServiceMonitors.[*].selector.matchLabels."sumologic.com/scrape"' true
}

function kube_prometheus_stack_set_remote_write_timeout_to_5s() {
  if [[ -z "$(yq r "${TEMP_FILE}" -- 'kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite')" ]]; then
    return
  fi

  if [[ -n "$(yq r "${TEMP_FILE}" -- 'kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.[*].remoteTimeout')" ]]; then
    echo
    info "kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite.[*].remoteTimeout is set"
    info "Please note that we've set it by default to 5s in 2.0.0"
  fi
}

function migrate_sumologic_sources() {
  # Nothing to migrate, return
  if [[ -z $(yq r "${TEMP_FILE}" sumologic.sources) ]] ; then
    return
  fi

  info "Migrating sumologic.sources to sumologic.collector.sources"
  yq m -i \
    "${TEMP_FILE}" \
    <(
      yq p \
      <(yq r "${TEMP_FILE}" "sumologic.sources") \
      "sumologic.collector.sources" \
    )
  yq d -i "${TEMP_FILE}" "sumologic.sources"
}

function migrate_sumologic_setup_fields() {
  # Nothing to migrate, return
  if [[ -z $(yq r "${TEMP_FILE}" sumologic.setup.fields) ]] ; then
    return
  fi

  info "Migrating sumologic.setup.fields to sumologic.collector.fields"
  yq m -i \
    "${TEMP_FILE}" \
    <(
      yq p \
      <(yq r "${TEMP_FILE}" "sumologic.setup.fields") \
      "sumologic.collector.fields" \
    )
  yq d -i "${TEMP_FILE}" "sumologic.setup.fields"
}

function migrate_metrics_server() {
  local metrics_server
  readonly metrics_server="$(yq r "${TEMP_FILE}" metrics-server)"

  # Nothing to migrate, return
  if [[ -z "${metrics_server}" ]] ; then
    return
  fi

  info "Migrating metrics-server"

  local param
  local v
  for v in $(yq r - "args[*]" <<< "${metrics_server}" )
  do
    # Strip '--' prefix
    v="${v/#--/}"

    # Split on '='
    IFS='=' read -ra param <<< "${v}"

    # 2 entries: this key has a value so use it
    if [[ ${#param[@]} -eq 2 ]]; then
      yq w -i "${TEMP_FILE}" "metrics-server.extraArgs.${param[0]}" "${param[1]}"
    # 1 entry: this key has no value hence it's just a boolean flag
    elif [[ ${#param[@]} -eq 1 ]]; then
      yq w -i "${TEMP_FILE}" "metrics-server.extraArgs.${param[0]}" true
    else
      warning "Problem migrating metrics-server args: ${param[*]}"
    fi
  done

  yq d -i "${TEMP_FILE}" "metrics-server.args"
}

function delete_migrated_unused_keys() {
  IFS=$'\n' read -r -d ' ' -a MAPPINGS_KEYS_TO_DELETE <<< "${KEYS_TO_DELETE}"
  readonly MAPPINGS_KEYS_TO_DELETE
  for i in "${MAPPINGS_KEYS_TO_DELETE[@]}"; do
    yq d -i "${TEMP_FILE}" -- "${i}"
  done
}

function migrate_customer_keys() {
  # Convert variables to arrays
  set +e
  IFS=$'\n' read -r -d ' ' -a MAPPINGS <<< "${KEY_MAPPINGS}"
  readonly MAPPINGS
  IFS=$'\n' read -r -d ' ' -a MAPPINGS_KEY_VALUE <<< "${KEY_VALUE_MAPPINGS}"
  readonly MAPPINGS_KEY_VALUE
  IFS=$'\n' read -r -d ' ' -a MAPPINGS_MULTIPLE <<< "${KEY_MAPPINGS_MULTIPLE}"
  readonly MAPPINGS_MULTIPLE
  set -e

  readonly CUSTOMER_KEYS=$(yq --printMode p r "${OLD_VALUES_YAML}" -- '**')

  for key in ${CUSTOMER_KEYS}; do
    if [[ ${MAPPINGS[*]} =~ ${key}: ]]; then
      # whatever you want to do when arr contains value
      for i in "${MAPPINGS[@]}"; do
        IFS=':' read -r -a maps <<< "${i}"
        if [[ ${maps[0]} == "${key}" ]]; then
          info "Mapping ${key} into ${maps[1]}"
          yq w -i "${TEMP_FILE}" -- "${maps[1]}" "$(yq r "${OLD_VALUES_YAML}" -- "${maps[0]}")"
          yq d -i "${TEMP_FILE}" -- "${maps[0]}"
        fi
      done
    elif [[ ${MAPPINGS_MULTIPLE[*]} =~ ${key}: ]]; then
      # whatever you want to do when arr contains value
      info "Mapping ${key} into:"
      for i in "${MAPPINGS_MULTIPLE[@]}"; do
        IFS=':' read -r -a maps <<< "${i}"
        if [[ ${maps[0]} == "${key}" ]]; then
          for element in "${maps[@]:1}"; do
            info "- ${element}"
            yq w -i "${TEMP_FILE}" -- "${element}" "$(yq r "${OLD_VALUES_YAML}" -- "${maps[0]}")"
            yq d -i "${TEMP_FILE}" -- "${maps[0]}"
          done
        fi
      done
    else
      yq w -i "${TEMP_FILE}" -- "${key}" "$(yq r "${OLD_VALUES_YAML}" -- "${key}")"
    fi

    for i in "${MAPPINGS_KEY_VALUE[@]}"; do
      IFS=':' read -r -a maps <<< "${i}"
      if [[ ${maps[0]} == "${key}" ]]; then
        old_value=$(yq r "${OLD_VALUES_YAML}" -- "${key}")

        if [[ ${maps[1]} == "${old_value}" ]]; then
          info "Mapping ${key}'s value from ${maps[1]} into ${maps[2]} "
          yq w -i "${TEMP_FILE}" -- "${maps[0]}" "${maps[2]}"
        fi
      fi
    done

  done
  echo
}

function get_regex() {
    # Get regex from old yaml file and strip `'` and `"` from beginning/end of it
    local write_index="${1}"
    local relabel_index="${2}"
    yq r "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${write_index}].writeRelabelConfigs[${relabel_index}].regex" | sed -e "s/^'//" -e 's/^"//' -e "s/'$//" -e 's/"$//'
}

function check_user_image() {
  # Check user's image and echo warning if the image has been changed
  local USER_VERSION
  readonly USER_VERSION="$(yq r "${OLD_VALUES_YAML}" -- image.tag)"
  local USER_IMAGE_REPOSITORY
  readonly USER_IMAGE_REPOSITORY="$(yq r "${OLD_VALUES_YAML}" -- image.repository)"
  if [[ -n "${USER_VERSION}" ]]; then
    if [[ "${USER_VERSION}" =~ ^"${PREVIOUS_VERSION}"\.[[:digit:]]+$ ]]; then
      info "Migrating from image.tag '${USER_VERSION}' to sumologic.setup.job.image.tag '2.0.0'"
      yq w -i "${TEMP_FILE}" -- sumologic.setup.job.image.tag 2.0.0
      info "Migrating from image.repository '${USER_IMAGE_REPOSITORY}' to sumologic.setup.job.image.repository 'public.ecr.aws/sumologic/kubernetes-setup'"
      yq w -i "${TEMP_FILE}" -- sumologic.setup.job.image.repository "public.ecr.aws/sumologic/kubernetes-setup"

      info "Migrating from image.tag '${USER_VERSION}' to fluentd.image.tag '1.11.5-sumo-0'"
      yq w -i "${TEMP_FILE}" -- fluentd.image.tag '1.11.5-sumo-0'
      info "Migrating from image.repository '${USER_IMAGE_REPOSITORY}' to fluentd.image.repository 'public.ecr.aws/sumologic/kubernetes-fluentd'"
      yq w -i "${TEMP_FILE}" -- fluentd.image.repository "public.ecr.aws/sumologic/kubernetes-fluentd"
    else
      warning "You are using unsupported version: ${USER_VERSION}"
      warning "Please upgrade to '${PREVIOUS_VERSION}.x' or ensure that new_values.yaml is valid"
    fi
  fi
}

function check_fluentd_persistence() {
  readonly FLUENTD_PERSISTENCE="$(yq r "${OLD_VALUES_YAML}" -- fluentd.persistence.enabled)"
  if [[ "${FLUENTD_PERSISTENCE}" == "false" ]]; then
    warning "You have fluentd.persistence.enabled set to 'false'"
    warning "This chart starting with 2.0 sets it to 'true' by default"
    warning "We're migrating your values.yaml with persistence set to 'false'"
    warning "Please refer to the following doc in in case you wish to enable it:"
    warning "https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/deploy/docs/Best_Practices.md#fluentd-file-based-buffer"
  fi
}

function fix_yq() {
  # account for yq bug that stringifies empty maps
  sed -i.bak "s/'{}'/{}/g" "${TEMP_FILE}"
}

function rename_temp_file() {
  mv "${TEMP_FILE}" new_values.yaml
}

function cleanup_bak_file() {
  rm "${TEMP_FILE}.bak"
}

function echo_footer() {
  echo
  echo "Thank you for upgrading to v2.0.0 of the Sumo Logic Kubernetes Collection Helm chart."
  echo "A new yaml file has been generated for you. Please check the current directory for new_values.yaml."
}

check_if_print_help_and_exit "${OLD_VALUES_YAML}"
check_bash_version
check_required_command yq
check_yq_version
check_required_command grep
check_required_command sed

create_temp_file

migrate_customer_keys

migrate_prometheus_recording_rules
add_new_scrape_labels_to_prometheus_service_monitors
migrate_prometheus_operator_to_kube_prometheus_stack
kube_prometheus_stack_set_remote_write_timeout_to_5s
kube_prometheus_stack_migrate_remote_write_urls
kube_prometheus_stack_update_remote_write_regexes
kube_prometheus_stack_migrate_chart_env_variable

migrate_sumologic_sources
migrate_sumologic_setup_fields
migrate_metrics_server

check_user_image
check_fluentd_persistence

fix_yq
rename_temp_file
cleanup_bak_file

echo_footer

exit 0
