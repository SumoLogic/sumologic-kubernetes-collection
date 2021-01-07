#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

readonly OLD_VALUES_YAML="${1:---help}"
readonly HELM_RELEASE_NAME="${2:-collection}"
readonly NAMESPACE="${3:-sumologic}"
readonly PREVIOUS_VERSION=0.17

readonly TEMP_FILE=upgrade-1.0.0-temp-file

readonly MIN_BASH_VERSION=4.0
readonly MIN_YQ_VERSION=3.4.1

readonly KEY_MAPPINGS="
eventsDeployment.nodeSelector:fluentd.events.statefulset.nodeSelector
eventsDeployment.resources.limits.cpu:fluentd.events.statefulset.resources.limits.cpu
eventsDeployment.resources.limits.memory:fluentd.events.statefulset.resources.limits.memory
eventsDeployment.resources.requests.cpu:fluentd.events.statefulset.resources.requests.cpu
eventsDeployment.resources.requests.memory:fluentd.events.statefulset.resources.requests.memory
eventsDeployment.tolerations:fluentd.events.statefulset.tolerations
sumologic.addTimestamp:fluentd.logs.output.addTimestamp
sumologic.chunkLimitSize:fluentd.buffer.chunkLimitSize
sumologic.eventCollectionEnabled:fluentd.events.enabled
sumologic.events.sourceCategory:fluentd.events.sourceCategory
sumologic.fluentd.buffer:fluentd.buffer.type
sumologic.fluentdLogLevel:fluentd.logLevel
sumologic.flushInterval:fluentd.buffer.flushInterval
sumologic.k8sMetadataFilter.cacheRefresh:fluentd.metadata.cacheRefresh
sumologic.k8sMetadataFilter.cacheSize:fluentd.metadata.cacheSize
sumologic.k8sMetadataFilter.cacheTtl:fluentd.metadata.cacheTtl
sumologic.k8sMetadataFilter.verifySsl:fluentd.logs.containers.k8sMetadataFilter.verifySsl
sumologic.k8sMetadataFilter.watch:fluentd.logs.containers.k8sMetadataFilter.watch
sumologic.logFormat:fluentd.logs.output.logFormat
sumologic.numThreads:fluentd.buffer.numThreads
sumologic.queueChunkLimitSize:fluentd.buffer.queueChunkLimitSize
sumologic.timestampKey:fluentd.logs.output.timestampKey
sumologic.totalLimitSize:fluentd.buffer.totalLimitSize
sumologic.verifySsl:fluentd.verifySsl
sumologic.watchResourceEventsOverrides:fluentd.events.watchResourceEventsOverrides"

readonly KEY_MAPPINGS_MULTIPLE="
deployment.affinity:fluentd.logs.statefulset.affinity:fluentd.metrics.statefulset.affinity
deployment.nodeSelector:fluentd.logs.statefulset.nodeSelector:fluentd.metrics.statefulset.nodeSelector
deployment.podAntiAffinity:fluentd.logs.statefulset.podAntiAffinity:fluentd.metrics.statefulset.podAntiAffinity
deployment.replicaCount:fluentd.logs.statefulset.replicaCount:fluentd.metrics.statefulset.replicaCount
deployment.resources.limits.cpu:fluentd.logs.statefulset.resources.limits.cpu:fluentd.metrics.statefulset.resources.limits.cpu
deployment.resources.limits.memory:fluentd.logs.statefulset.resources.limits.memory:fluentd.metrics.statefulset.resources.limits.memory
deployment.resources.requests.cpu:fluentd.logs.statefulset.resources.requests.cpu:fluentd.metrics.statefulset.resources.requests.cpu
deployment.resources.requests.memory:fluentd.logs.statefulset.resources.requests.memory:fluentd.metrics.statefulset.resources.requests.memory
deployment.tolerations:fluentd.logs.statefulset.tolerations:fluentd.metrics.statefulset.tolerations
sumologic.fluentd.autoscaling.enabled:fluentd.logs.autoscaling.enabled:fluentd.metrics.autoscaling.enabled
sumologic.fluentd.autoscaling.maxReplicas:fluentd.logs.autoscaling.maxReplicas:fluentd.metrics.autoscaling.maxReplicas
sumologic.fluentd.autoscaling.minReplicas:fluentd.logs.autoscaling.minReplicas:fluentd.metrics.autoscaling.minReplicas
sumologic.fluentd.autoscaling.targetCPUUtilizationPercentage:fluentd.logs.autoscaling.targetCPUUtilizationPercentage:fluentd.metrics.autoscaling.targetCPUUtilizationPercentage
sumologic.excludeContainerRegex:fluentd.logs.containers.excludeContainerRegex:fluentd.logs.default.excludeContainerRegex:fluentd.logs.systemd.excludeContainerRegex:fluentd.logs.kubelet.excludeContainerRegex
sumologic.excludeHostRegex:fluentd.logs.containers.excludeHostRegex:fluentd.logs.default.excludeHostRegex:fluentd.logs.systemd.excludeHostRegex:fluentd.logs.kubelet.excludeHostRegex
sumologic.excludeNamespaceRegex:fluentd.logs.containers.excludeNamespaceRegex:fluentd.logs.default.excludeNamespaceRegex:fluentd.logs.systemd.excludeNamespaceRegex:fluentd.logs.kubelet.excludeNamespaceRegex
sumologic.excludePodRegex:fluentd.logs.containers.excludePodRegex:fluentd.logs.default.excludePodRegex:fluentd.logs.systemd.excludePodRegex:fluentd.logs.kubelet.excludePodRegex
sumologic.sourceCategory:fluentd.logs.containers.sourceCategory:fluentd.logs.default.sourceCategory:fluentd.logs.systemd.sourceCategory:fluentd.logs.kubelet.sourceCategory
sumologic.sourceCategoryPrefix:fluentd.logs.containers.sourceCategoryPrefix:fluentd.logs.default.sourceCategoryPrefix:fluentd.logs.systemd.sourceCategoryPrefix:fluentd.logs.kubelet.sourceCategoryPrefix
sumologic.sourceCategoryReplaceDash:fluentd.logs.containers.sourceCategoryReplaceDash:fluentd.logs.default.sourceCategoryReplaceDash:fluentd.logs.systemd.sourceCategoryReplaceDash:fluentd.logs.kubelet.sourceCategoryReplaceDash
sumologic.sourceName:fluentd.logs.containers.sourceName:fluentd.logs.default.sourceName:fluentd.logs.systemd.sourceName:fluentd.logs.kubelet.sourceName
"

readonly KEY_MAPPINGS_EMPTY="
deployment
eventsDeployment
fluentd.autoscaling
fluentd.rawConfig
fluentd.statefulset
sumologic.addStream
sumologic.addTime
sumologic.events
sumologic.fluentd
sumologic.k8sMetadataFilter
sumologic.kubernetesMeta
sumologic.kubernetesMetaReduce"

readonly KEY_CASTS_STRING="
fluent-bit.backend.forward.tls
fluent-bit.backend.forward.tls_verify
sumologic.setup.clusterRole.annotations.\"helm.sh/hook-weight\"
sumologic.setup.clusterRoleBinding.annotations.\"helm.sh/hook-weight\"
sumologic.setup.configMap.annotations.\"helm.sh/hook-weight\"
sumologic.setup.job.annotations.\"helm.sh/hook-weight\"
sumologic.setup.serviceAccount.annotations.\"helm.sh/hook-weight\"
"

# Prometheus changes
# Diff of prometheus regexes:
# git diff v1.0.0 v0.17.1 deploy/helm/sumologic/values.yaml | \
# grep -E '(regex|url)\:' | \
# grep -E "^(\-|\+)\s+ (regex|url)\:" | \
# sed 's|-        url: http://$(CHART).$(NAMESPACE).svc.cluster.local:9888||' | \
# sed 's/$/\\n/'
#
# minus means 1.0.0 regex
# plus means 0.17.2 regex

readonly EXPECTED_PROMETHEUS_METRICS_CHANGES="/prometheus.metrics.state
-          regex: kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_deployment_spec_replicas|kube_deployment_status_replicas_available|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)
+          regex: kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_daemonset_metadata_generation|kube_deployment_metadata_generation|kube_deployment_spec_paused|kube_deployment_spec_replicas|kube_deployment_spec_strategy_rollingupdate_max_unavailable|kube_deployment_status_replicas_available|kube_deployment_status_observed_generation|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_spec_unschedulable|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)
/prometheus.metrics.controller-manager
/prometheus.metrics.scheduler
/prometheus.metrics.apiserver
-          regex: apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_(?:duration_seconds|latencies)_(?:count|sum)|apiserver_request_latencies_summary(?:|_count|_sum)|etcd_request_cache_(?:add|get)_(?:duration_seconds|latencies_summary)_(?:count|sum)|etcd_helper_cache_(?:hit|miss)_(?:count|total))
+          regex: apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_latenc(?:ies|y_seconds).*|etcd_request_cache_get_latenc(?:ies_summary|y_seconds).*|etcd_request_cache_add_latenc(?:ies_summary|y_seconds).*|etcd_helper_cache_hit_(?:count|total)|etcd_helper_cache_miss_(?:count|total))
/prometheus.metrics.kubelet
-          regex: kubelet;(?:kubelet_docker_operations_errors(?:|_total)|kubelet_(?:docker|runtime)_operations_duration_seconds_(?:count|sum)|kubelet_running_(?:container|pod)_count|kubelet_(:?docker|runtime)_operations_latency_microseconds(?:|_count|_sum))
+          regex: kubelet;(?:kubelet_docker_operations_errors|kubelet_docker_operations_latency_microseconds|kubelet_running_container_count|kubelet_running_pod_count|kubelet_runtime_operations_latency_microseconds.*)
/prometheus.metrics.container
-          regex: kubelet;.+;(?:container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_fs_usage_bytes|container_fs_limit_bytes)
+          regex: kubelet;.+;(?:container_cpu_load_average_10s|container_cpu_system_seconds_total|container_cpu_usage_seconds_total|container_cpu_cfs_throttled_seconds_total|container_memory_usage_bytes|container_memory_swap|container_memory_working_set_bytes|container_spec_memory_limit_bytes|container_spec_memory_swap_limit_bytes|container_spec_memory_reservation_limit_bytes|container_spec_cpu_quota|container_spec_cpu_period|container_fs_usage_bytes|container_fs_limit_bytes|container_fs_reads_bytes_total|container_fs_writes_bytes_total|)
/prometheus.metrics.container
-          regex: kubelet;(?:container_network_receive_bytes_total|container_network_transmit_bytes_total)
+          regex: kubelet;(?:container_network_receive_bytes_total|container_network_transmit_bytes_total|container_network_receive_errors_total|container_network_transmit_errors_total|container_network_receive_packets_dropped_total|container_network_transmit_packets_dropped_total)
/prometheus.metrics.node
-          regex: node-exporter;(?:node_load1|node_load5|node_load15|node_cpu_seconds_total)
+          regex: node-exporter;(?:node_load1|node_load5|node_load15|node_cpu_seconds_total|node_memory_MemAvailable_bytes|node_memory_MemTotal_bytes|node_memory_Buffers_bytes|node_memory_SwapCached_bytes|node_memory_Cached_bytes|node_memory_MemFree_bytes|node_memory_SwapFree_bytes|node_ipvs_incoming_bytes_total|node_ipvs_outgoing_bytes_total|node_ipvs_incoming_packets_total|node_ipvs_outgoing_packets_total|node_disk_reads_completed_total|node_disk_writes_completed_total|node_disk_read_bytes_total|node_disk_written_bytes_total|node_filesystem_avail_bytes|node_filesystem_free_bytes|node_filesystem_size_bytes|node_filesystem_files)
/prometheus.metrics.operator.rule
-          regex: 'cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:'
+          regex: 'cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_cpu:rate:sum|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|instance:node_network_transmit_bytes:rate:sum|instance:node_cpu:ratio|cluster:node_cpu:sum_rate5m|cluster:node_cpu:ratio|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|:node_memory_MemFreeCachedBuffers_bytes:sum|:node_memory_MemTotal_bytes:sum|node:node_memory_bytes_available:sum|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:'
/prometheus.metrics"

# https://slides.com/perk/how-to-train-your-bash#/41
readonly LOG_FILE="/tmp/$(basename "$0").log"
info()    { echo -e "[INFO]    $*" | tee -a "${LOG_FILE}" >&2 ; }
warning() { echo -e "[WARNING] $*" | tee -a "${LOG_FILE}" >&2 ; }
error()   { echo -e "[ERROR]   $*" | tee -a "${LOG_FILE}" >&2 ; }
fatal()   { echo -e "[FATAL]   $*" | tee -a "${LOG_FILE}" >&2 ; exit 1 ; }

function print_help_and_exit() {
  readonly MAN="Thank you for upgrading to v1.0.0 of the Sumo Logic Kubernetes Collection Helm chart.
As part of this major release, the format of the values.yaml file has changed.

This script will automatically take the configurations of your existing values.yaml
and return one that is compatible with v1.0.0.

Requirements:
  yq (>= ${MIN_YQ_VERSION}) https://github.com/mikefarah/yq/releases/tag/3.2.1
  grep
  sed
  bash (>= ${MIN_BASH_VERSION})

Usage:
  # for default helm release name 'collection' and namespace 'sumologic'
  ./upgrade-1.0.0.sh /path/to/values.yaml

  # for non-default helm release name and k8s namespace
  ./upgrade-1.0.0.sh /path/to/values.yaml helm_release_name k8s_namespace

Returns:
  new_values.yaml

For more details, please refer to Migration steps and Changelog here:
https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v1.0/deploy/docs/v1_migration_doc.md"

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

function check_yq_version() {
  local yq_version
  yq_version=$(yq --version | grep -oE '[^[:space:]]+$')

  check_app_version "grep" "${MIN_YQ_VERSION}" "${yq_version}"
}

function check_bash_version() {
  check_app_version "bash" "${MIN_BASH_VERSION}" "${BASH_VERSION}"
}

function create_temp_file() {
  echo -n > "${TEMP_FILE}"
}

function migrate_customer_keys() {
  # Convert variables to arrays
  set +e
  IFS=$'\n' read -r -d ' ' -a MAPPINGS <<< "${KEY_MAPPINGS}"
  readonly MAPPINGS
  IFS=$'\n' read -r -d ' ' -a MAPPINGS_MULTIPLE <<< "${KEY_MAPPINGS_MULTIPLE}"
  readonly MAPPINGS_MULTIPLE
  IFS=$'\n' read -r -d ' ' -a MAPPINGS_EMPTY <<< "${KEY_MAPPINGS_EMPTY}"
  readonly MAPPINGS_EMPTY
  IFS=$'\n' read -r -d ' ' -a CASTS_STRING <<< "${KEY_CASTS_STRING}"
  readonly CASTS_STRING
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

    if [[ "${MAPPINGS_EMPTY[*]}" =~ ${key} ]]; then
      info "Removing ${key}"
      yq d -i "${TEMP_FILE}" -- "${key}"
    fi

    if [[ "${CASTS_STRING[*]}" =~ ${key} ]]; then
      info "Casting ${key} to str"
      # As yq doesn't cast `on` and `off` from bool to cast, we use sed based casts
      yq w -i "${TEMP_FILE}" -- "${key}" "$(yq r "${OLD_VALUES_YAML}" "${key}")__YQ_REPLACEMENT_CAST"
      sed -i.bak 's/\(^.*: \)\(.*\)__YQ_REPLACEMENT_CAST/\1"\2"/g' "${TEMP_FILE}"
    fi
  done
  echo
}

function migrate_add_stream_and_add_time() {
  # Preserve the functionality of addStream=false or addTime=false
  if [ "$(yq r "${OLD_VALUES_YAML}" -- sumologic.addStream)" == "false" ] && [ "$(yq r "${OLD_VALUES_YAML}" -- sumologic.addTime)" == "false" ]; then
    REMOVE="stream,time"
  elif [ "$(yq r "${OLD_VALUES_YAML}" -- sumologic.addStream)" == "false" ]; then
    REMOVE="stream"
  elif [ "$(yq r "${OLD_VALUES_YAML}" -- sumologic.addTime)" == "false" ]; then
    REMOVE="time"
  else
    REMOVE=
  fi

# Add filter on beginning of current filters
FILTER="<filter containers.**>
  @type record_modifier
  remove_keys ${REMOVE}
</filter>"

  # Apply changes if required
  if [ "$(yq r "${OLD_VALUES_YAML}" -- sumologic.addStream)" == "false" ] || [ "$(yq r "${OLD_VALUES_YAML}" -- sumologic.addTime)" == "false" ]; then
    info "Creating fluentd.logs.containers.extraFilterPluginConf to preserve addStream/addTime functionality"
    yq w -i "${TEMP_FILE}" -- fluentd.logs.containers.extraFilterPluginConf "${FILTER}"
  fi
}

function migrate_pre_upgrade_hook() {
  # Keep pre-upgrade hook
  if [[ -n "$(yq r "${TEMP_FILE}" -- sumologic.setup)" ]]; then
    info "Updating setup hooks (sumologic.setup.*.annotations[helm.sh/hook]) to 'pre-install,pre-upgrade'"
    yq w -i "${TEMP_FILE}" -- 'sumologic.setup.*.annotations[helm.sh/hook]' 'pre-install,pre-upgrade'
  fi
}

function check_falco_state() {
  # Print information about falco state
  if [[ "$(yq r "${TEMP_FILE}" -- falco.enabled)" == 'true' ]]; then
    info 'falco will be enabled. Change "falco.enabled" to "false" if you want to disable it (default for 1.0)'
  else
    info 'falco will be disabled. Change "falco.enabled" to "true" if you want to enable it'
  fi
}

function get_regex() {
    # Get regex from old yaml file and strip `'` and `"` from beginning/end of it
    local write_index="${1}"
    local relabel_index="${2}"
    yq r "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${write_index}].writeRelabelConfigs[${relabel_index}].regex" | sed -e "s/^'//" -e 's/^"//' -e "s/'$//" -e 's/"$//'
}

function get_release_regex() {
  local metric_name="${1}"
  local str_grep="${2}"
  local filter="${3}"

  echo "${EXPECTED_PROMETHEUS_METRICS_CHANGES}" | grep -A 3 "${metric_name}$" | "${filter}" -n 3 | grep -E "${str_grep}" | grep -oE ': .*' | sed 's/: //' | sed -e "s/^'//" -e 's/^"//' -e "s/'$//" -e 's/"$//'
}

function migrate_prometheus_metrics() {


  metrics_length="$(yq r -l "${OLD_VALUES_YAML}" -- 'prometheus-operator.prometheus.prometheusSpec.remoteWrite')"
  metrics_length="$(( metrics_length - 1))"

  for i in $(seq 0 "${metrics_length}"); do
      metric_name="$(yq r "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].url" | grep -oE '/prometheus\.metrics.*' || true)"
      metric_regex_length="$(yq r -l "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs")"
      metric_regex_length="$(( metric_regex_length - 1))"

      for j in $(seq 0 "${metric_regex_length}"); do
          metric_regex_action=$(yq r "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].action")
          if [[ "${metric_regex_action}" = "keep" ]]; then
              break
          fi
      done
      regexes_len="$( (echo "${EXPECTED_PROMETHEUS_METRICS_CHANGES}" | grep -A 2 "${metric_name}$" | grep regex || true ) | wc -l)"
      if [[ "${regexes_len}" -eq "2" ]]; then

        regex_1_0="$(get_release_regex "${metric_name}" '^\s*-' 'head')"
        regex_0_17="$(get_release_regex "${metric_name}" '^\s*\+' 'head')"
        regex="$(get_regex "${i}" "${j}")"
        if [[ "${regex_0_17}" = "${regex}" ]]; then
            yq w -i "${TEMP_FILE}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
        else
            warning "Changes of regex for 'prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}]' (${metric_name}) detected, please migrate it manually"
        fi
      fi

      if [[ "${metric_name}" = "/prometheus.metrics.container" ]]; then
          regex_1_0="$(get_release_regex "${metric_name}" '^\s*-' 'head')"
          regex_0_17="$(get_release_regex "${metric_name}" '^\s*\+' 'head')"
          regex="$(get_regex "${i}" "${j}")"
          if [[ "${regex_0_17}" = "${regex}" ]]; then
              yq w -i "${TEMP_FILE}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
          else
              regex_1_0="$(get_release_regex "${metric_name}" '^\s*-' 'tail')"
              regex_0_17="$(get_release_regex "${metric_name}" '^\s*\+' 'tail')"
              if [[ "${regex_0_17}" = "${regex}" ]]; then
                  yq w -i "${TEMP_FILE}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
              else
                  warning "Changes of regex for 'prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}]' (${metric_name}) detected, please migrate it manually"
              fi
          fi
      fi
  done
}

function fix_fluentbit_env() {
  # Fix fluent-bit env
  if [[ -n "$(yq r "${TEMP_FILE}" -- fluent-bit.env)" ]]; then
    info "Patching fluent-bit CHART environmental variable"
    yq w -i "${TEMP_FILE}" -- "fluent-bit.env(name==CHART).valueFrom.configMapKeyRef.key" "fluentdLogs"
  fi
}

function fix_prometheus_service_monitors() {
  # Fix prometheus service monitors
  if [[ -n "$(yq r "${TEMP_FILE}" -- prometheus-operator.prometheus.additionalServiceMonitors)" ]]; then
    info "Patching prometheus-operator.prometheus.additionalServiceMonitors"
    yq d -i "${TEMP_FILE}" -- "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE})"
    yq d -i "${TEMP_FILE}" -- "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE}-otelcol)"
    yq d -i "${TEMP_FILE}" -- "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE}-events)"
    echo "---
prometheus-operator:
  prometheus:
    additionalServiceMonitors:
      - name: ${HELM_RELEASE_NAME}-${NAMESPACE}-otelcol
        additionalLabels:
          app: ${HELM_RELEASE_NAME}-${NAMESPACE}-otelcol
        endpoints:
          - port: metrics
        namespaceSelector:
          matchNames:
            - ${NAMESPACE}
        selector:
          matchLabels:
            app: ${HELM_RELEASE_NAME}-${NAMESPACE}-otelcol
      - name: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-logs
        additionalLabels:
          app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-logs
        endpoints:
        - port: metrics
        namespaceSelector:
          matchNames:
          - ${NAMESPACE}
        selector:
          matchLabels:
            app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-logs
      - name: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-metrics
        additionalLabels:
          app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-metrics
        endpoints:
        - port: metrics
        namespaceSelector:
          matchNames:
          - ${NAMESPACE}
        selector:
          matchLabels:
            app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-metrics
      - name: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-events
        additionalLabels:
          app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-events
        endpoints:
          - port: metrics
        namespaceSelector:
          matchNames:
            - ${NAMESPACE}
        selector:
          matchLabels:
            app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-events" | yq m -a=append -i "${TEMP_FILE}" -
  fi

  if [[ -n "$(yq r "${TEMP_FILE}" -- prometheus-operator.prometheus.prometheusSpec.containers)" ]]; then
    info "Patching prometheus CHART environmental variable"
    yq w -i "${TEMP_FILE}" -- "prometheus-operator.prometheus.prometheusSpec.containers(name==prometheus-config-reloader).env(name==CHART).valueFrom.configMapKeyRef.key" "fluentdMetrics"
  fi
}

function check_user_image() {
  # Check user's image and echo warning if the image has been changed
  readonly USER_VERSION="$(yq r "${OLD_VALUES_YAML}" -- image.tag)"
  if [[ -n "${USER_VERSION}" ]]; then
    if [[ "${USER_VERSION}" =~ ^"${PREVIOUS_VERSION}"\.[[:digit:]]+$ ]]; then
      yq w -i "${TEMP_FILE}" -- image.tag 1.0.0
      info "Changing image.tag from '${USER_VERSION}' to '1.0.0'"
    else
      warning "You are using unsupported version: ${USER_VERSION}"
      warning "Please upgrade to '${PREVIOUS_VERSION}.x' or ensure that new_values.yaml is valid"
    fi
  fi
}

function migrate_fluentbit_db_path() {
  grep 'tail-db/tail-containers-state.db' "${TEMP_FILE}" 1>/dev/null 2>&1 || return 0
  # New fluent-bit db path
  info 'Replacing tail-db/tail-containers-state.db to tail-db/tail-containers-state-sumo.db'
  warning 'Please ensure that new fluent-bit configuration is correct'

  sed -i.bak 's?tail-db/tail-containers-state.db?tail-db/tail-containers-state-sumo.db?g' "${TEMP_FILE}"
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
  DONE="\nThank you for upgrading to v1.0.0 of the Sumo Logic Kubernetes Collection Helm chart.\nA new yaml file has been generated for you. Please check the current directory for new_values.yaml."
  echo -e "${DONE}"
}

check_if_print_help_and_exit "${OLD_VALUES_YAML}"
check_bash_version
check_required_command yq
check_yq_version
check_required_command grep
check_required_command sed

create_temp_file

migrate_customer_keys

migrate_add_stream_and_add_time
migrate_pre_upgrade_hook

check_falco_state

migrate_prometheus_metrics

fix_fluentbit_env
fix_prometheus_service_monitors

check_user_image
migrate_fluentbit_db_path

fix_yq
rename_temp_file
cleanup_bak_file

echo_footer

exit 0
