#!/bin/bash

#set -x

MAN="Thank you for upgrading to v1.0.0 of the Sumo Logic Kubernetes Collection Helm chart.
As part of this major release, the format of the values.yaml file has changed.

This script will automatically take the configurations of your existing values.yaml
and return one that is compatible with v1.0.0.

Requirements:
  yq (3.2.1) https://github.com/mikefarah/yq/releases/tag/3.2.1
  curl
  grep
  sed
  git diff in case of changes to Prometheus remote write regexes

Usage:
  # for default helm release name 'collection' and namespace 'sumologic'
  ./upgrade-1.0.0.sh /path/to/values.yaml

  # for non-default helm release name and k8s namespace
  ./upgrade-1.0.0.sh /path/to/values.yaml helm_release_name k8s_namespace

Returns:
  new_values.yaml

For more details, please refer to Migration steps and Changelog here: [link]
"


if [[ "$1" = "" ]] || [[ "$1" = "--help" ]]; then
  echo "$MAN"
  exit 1
fi

function check_required_command() {
  local command_to_check="$1"
  command -v ${command_to_check} >/dev/null 2>&1 || { echo >&2 "Required command is missing: ${command_to_check}"; echo >&2 "Please consult --help and install missing commands before continue. Aborting."; exit 1; }
}

check_required_command yq
yq --version | grep 3.2.1 >/dev/null 2>&1 || { echo >&2 "yq version is invalid. It should be exactly 3.2.1. Please install it properly: https://github.com/mikefarah/yq/releases/tag/3.2.1"; exit 1; }
check_required_command grep
check_required_command sed
check_required_command curl

readonly OLD_VALUES_YAML="$1"
readonly HELM_RELEASE_NAME="${2:-collection}"
readonly NAMESPACE="${3:-sumologic}"
readonly PREVIOUS_VERSION=0.17.2

URL=https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v1.0/deploy/helm/sumologic/values.yaml
curl -s $URL > new.yaml

readonly KEY_MAPPINGS="
eventsDeployment.nodeSelector:fluentd.events.statefulset.nodeSelector
eventsDeployment.resources.limits.cpu:fluentd.events.statefulset.resources.limits.cpu
eventsDeployment.resources.limits.memory:fluentd.events.statefulset.resources.limits.memory
eventsDeployment.resources.requests.cpu:fluentd.events.statefulset.resources.requests.cpu
eventsDeployment.resources.requests.memory:fluentd.events.statefulset.resources.requests.memory
eventsDeployment.tolerations:fluentd.events.statefulset.tolerations
sumologic.addStream:problems.sumologic.addStream
sumologic.addTime:problems.sumologic.addTime
sumologic.addTimestamp:fluentd.logs.output.addTimestamp
sumologic.chunkLimitSize:fluentd.buffer.chunkLimitSize
sumologic.eventCollectionEnabled:fluentd.events.enabled
sumologic.events.sourceCategory:fluentd.events.sourceCategory
sumologic.excludeContainerRegex:fluentd.logs.containers.excludeContainerRegex
sumologic.excludeHostRegex:fluentd.logs.containers.excludeHostRegex
sumologic.excludeNamespaceRegex:fluentd.logs.containers.excludeNamespaceRegex
sumologic.excludePodRegex:fluentd.logs.containers.excludePodRegex
sumologic.fluentd.buffer:fluentd.buffer.type
sumologic.fluentdLogLevel:fluentd.logLevel
sumologic.flushInterval:fluentd.buffer.flushInterval
sumologic.k8sMetadataFilter.cacheRefresh:fluentd.metadata.cacheRefresh
sumologic.k8sMetadataFilter.cacheSize:fluentd.metadata.cacheSize
sumologic.k8sMetadataFilter.cacheTtl:fluentd.metadata.cacheTtl
sumologic.k8sMetadataFilter.verifySsl:fluentd.logs.containers.k8sMetadataFilter.verifySsl
sumologic.k8sMetadataFilter.watch:fluentd.logs.containers.k8sMetadataFilter.watch
sumologic.kubernetesMeta:problems.sumologic.kubernetesMeta
sumologic.kubernetesMetaReduce:problems.sumologic.kubernetesMetaReduce
sumologic.logFormat:fluentd.logs.output.logFormat
sumologic.numThreads:fluentd.buffer.numThreads
sumologic.queueChunkLimitSize:fluentd.buffer.queueChunkLimitSize
sumologic.sourceCategory:fluentd.logs.containers.sourceCategory
sumologic.sourceCategoryPrefix:fluentd.logs.containers.sourceCategoryPrefix
sumologic.sourceCategoryReplaceDash:fluentd.logs.containers.sourceCategoryReplaceDash
sumologic.sourceName:fluentd.logs.containers.sourceName
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

IFS=$'\n' read -r -d '' -a MAPPINGS <<< "$KEY_MAPPINGS"
readonly MAPPINGS
IFS=$'\n' read -r -d '' -a MAPPINGS_MULTIPLE <<< "$KEY_MAPPINGS_MULTIPLE"
readonly MAPPINGS_MULTIPLE
IFS=$'\n' read -r -d '' -a MAPPINGS_EMPTY <<< "$KEY_MAPPINGS_EMPTY"
readonly MAPPINGS_EMPTY

echo > new.yaml
readonly CUSTOMER_KEYS=$(yq --printMode p r $OLD_VALUES_YAML -- '**')

for key in ${CUSTOMER_KEYS}; do
  echo mapping old key: $key

  if [[ "${MAPPINGS[@]}" =~ "${key}" ]]; then
    # whatever you want to do when arr contains value
    for i in ${MAPPINGS[@]}; do
      IFS=':' read -r -a maps <<< "${i}"
      if [[ ${maps[0]} == $key ]]; then
        echo into new key: ${maps[1]}
        yq w -i new.yaml -- ${maps[1]} "$(yq r $OLD_VALUES_YAML -- ${maps[0]})"
        yq d -i new.yaml -- ${maps[0]}
      fi
    done
  elif [[ "${MAPPINGS_MULTIPLE[@]}" =~ "${key}" ]]; then
    # whatever you want to do when arr contains value
    for i in ${MAPPINGS_MULTIPLE[@]}; do
      IFS=':' read -r -a maps <<< "${i}"
      if [[ ${maps[0]} == $key ]]; then
        for element in ${maps[@]:1}; do
          echo into new key: ${element}
          yq w -i new.yaml -- ${element} "$(yq r $OLD_VALUES_YAML -- ${maps[0]})"
          yq d -i new.yaml -- ${maps[0]}
        done
      fi
    done
  else
    echo into new key: $key
    yq w -i new.yaml -- $key "$(yq r $OLD_VALUES_YAML -- $key)"
  fi

  if [[ "${MAPPINGS_EMPTY[@]}" =~ "${key}" ]]; then
    echo removing $key
    yq d -i new.yaml -- "${key}"
  fi

  echo
done

# Special case for fluentd.events.WatchResourceEventsOverrides
# as this config is commented out by default but we will write it as empty string
# which will not work
if [ "$(yq r $OLD_VALUES_YAML -- sumologic.watchResourceEventsOverrides)" = "" ]; then
  yq d -i new.yaml -- fluentd.events.watchResourceEventsOverrides
fi

# Preserve the functionality of addStream=false or addTime=false
if [ "$(yq r $OLD_VALUES_YAML -- sumologic.addStream)" == "false" ] && [ "$(yq r $OLD_VALUES_YAML -- sumologic.addTime)" == "false" ]; then
  REMOVE="stream,time"
elif [ "$(yq r $OLD_VALUES_YAML -- sumologic.addStream)" == "false" ]; then
  REMOVE="stream"
elif [ "$(yq r $OLD_VALUES_YAML -- sumologic.addTime)" == "false" ]; then
  REMOVE="time"
fi

# Add filter on beginning of current filters
FILTER="<filter containers.**>
  @type record_modifier
  remove_keys $REMOVE
</filter>
$(yq r new.yaml -- fluentd.logs.containers.extraFilterPluginConf)"

# Apply changes if required
if [ "$(yq r $OLD_VALUES_YAML -- sumologic.addStream)" == "false" ] || [ "$(yq r $OLD_VALUES_YAML -- sumologic.addTime)" == "false" ]; then
  yq w -i new.yaml -- fluentd.logs.containers.extraFilterPluginConf "$FILTER"
fi

# Keep pre-upgrade hook
if [[ ! -z "$(yq r new.yaml -- sumologic.setup)" ]]; then
  yq w -i new.yaml -- 'sumologic.setup.*.annotations[helm.sh/hook]' 'pre-install,pre-upgrade'
fi

# Print information about falco state
if [[ "$(yq r new.yaml -- falco.enabled)" == 'false' ]]; then
  echo 'falco will be disabled. Change "falco.enabled" to "true" if you want to enable it'
else
  echo 'falco will be enabled. Change "falco.enabled" to "false" if you want to disable it (default for 1.0)'
fi

# Prometheus changes
# Diff of prometheus regexes:
# git diff v1.0.0 v0.17.1 deploy/helm/sumologic/values.yaml | \
# grep -E '(regex|url)\:' | \
# grep -E "^(\-|\+)\s+ (regex|url)\:" | \
# sed 's|-        url: http://$(CHART).$(NAMESPACE).svc.cluster.local:9888||' | \
# sed 's/$/\\n/'
#
# minus means 1.0.0 regex
# plus means 0.17.1 regex

expected_metrics="/prometheus.metrics.state\n
-          regex: kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_deployment_spec_replicas|kube_deployment_status_replicas_available|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)\n
+          regex: kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_daemonset_metadata_generation|kube_deployment_metadata_generation|kube_deployment_spec_paused|kube_deployment_spec_replicas|kube_deployment_spec_strategy_rollingupdate_max_unavailable|kube_deployment_status_replicas_available|kube_deployment_status_observed_generation|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_spec_unschedulable|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)\n
/prometheus.metrics.controller-manager\n
/prometheus.metrics.scheduler\n
/prometheus.metrics.apiserver\n
-          regex: apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_(?:duration_seconds|latencies)_(?:count|sum)|apiserver_request_latencies_summary(?:|_count|_sum)|etcd_request_cache_(?:add|get)_(?:duration_seconds|latencies_summary)_(?:count|sum)|etcd_helper_cache_(?:hit|miss)_(?:count|total))\n
+          regex: apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_latenc(?:ies|y_seconds).*|etcd_request_cache_get_latenc(?:ies_summary|y_seconds).*|etcd_request_cache_add_latenc(?:ies_summary|y_seconds).*|etcd_helper_cache_hit_(?:count|total)|etcd_helper_cache_miss_(?:count|total))\n
/prometheus.metrics.kubelet\n
-          regex: kubelet;(?:kubelet_docker_operations_errors(?:|_total)|kubelet_(?:docker|runtime)_operations_duration_seconds_(?:count|sum)|kubelet_running_(?:container|pod)_count|kubelet_(:?docker|runtime)_operations_latency_microseconds(?:|_count|_sum))\n
+          regex: kubelet;(?:kubelet_docker_operations_errors|kubelet_docker_operations_latency_microseconds|kubelet_running_container_count|kubelet_running_pod_count|kubelet_runtime_operations_latency_microseconds.*)\n
/prometheus.metrics.container\n
-          regex: kubelet;.+;(?:container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_fs_usage_bytes|container_fs_limit_bytes)\n
+          regex: kubelet;.+;(?:container_cpu_load_average_10s|container_cpu_system_seconds_total|container_cpu_usage_seconds_total|container_cpu_cfs_throttled_seconds_total|container_memory_usage_bytes|container_memory_swap|container_memory_working_set_bytes|container_spec_memory_limit_bytes|container_spec_memory_swap_limit_bytes|container_spec_memory_reservation_limit_bytes|container_spec_cpu_quota|container_spec_cpu_period|container_fs_usage_bytes|container_fs_limit_bytes|container_fs_reads_bytes_total|container_fs_writes_bytes_total|)\n
/prometheus.metrics.container\n
-          regex: kubelet;(?:container_network_receive_bytes_total|container_network_transmit_bytes_total)\n
+          regex: kubelet;(?:container_network_receive_bytes_total|container_network_transmit_bytes_total|container_network_receive_errors_total|container_network_transmit_errors_total|container_network_receive_packets_dropped_total|container_network_transmit_packets_dropped_total)\n
/prometheus.metrics.node\n
-          regex: node-exporter;(?:node_load1|node_load5|node_load15|node_cpu_seconds_total)\n
+          regex: node-exporter;(?:node_load1|node_load5|node_load15|node_cpu_seconds_total|node_memory_MemAvailable_bytes|node_memory_MemTotal_bytes|node_memory_Buffers_bytes|node_memory_SwapCached_bytes|node_memory_Cached_bytes|node_memory_MemFree_bytes|node_memory_SwapFree_bytes|node_ipvs_incoming_bytes_total|node_ipvs_outgoing_bytes_total|node_ipvs_incoming_packets_total|node_ipvs_outgoing_packets_total|node_disk_reads_completed_total|node_disk_writes_completed_total|node_disk_read_bytes_total|node_disk_written_bytes_total|node_filesystem_avail_bytes|node_filesystem_free_bytes|node_filesystem_size_bytes|node_filesystem_files)\n
/prometheus.metrics.operator.rule\n
-          regex: 'cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:'\n
+          regex: 'cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_cpu:rate:sum|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|instance:node_network_transmit_bytes:rate:sum|instance:node_cpu:ratio|cluster:node_cpu:sum_rate5m|cluster:node_cpu:ratio|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|:node_memory_MemFreeCachedBuffers_bytes:sum|:node_memory_MemTotal_bytes:sum|node:node_memory_bytes_available:sum|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:'\n
/prometheus.metrics\n"

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

  echo -e ${expected_metrics} | grep -A 3 "${metric_name}$" | "${filter}" -n 3 | grep -E "${str_grep}" | grep -oE ': .*' | sed 's/: //' | sed -e "s/^'//" -e 's/^"//' -e "s/'$//" -e 's/"$//'
}

metrics_length="$(yq r -l "${OLD_VALUES_YAML}" -- 'prometheus-operator.prometheus.prometheusSpec.remoteWrite')"
metrics_length="$(( ${metrics_length} - 1))"

for i in $(seq 0 ${metrics_length}); do
    metric_name="$(yq r "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].url" | grep -oE '/prometheus\.metrics.*')"
    metric_regex_length="$(yq r -l "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs")"
    metric_regex_length="$(( ${metric_regex_length} - 1))"

    for j in $(seq 0 ${metric_regex_length}); do
        metric_regex_action=$(yq r "${OLD_VALUES_YAML}" -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].action")
        if [[ "${metric_regex_action}" = "keep" ]]; then
            break
        fi
    done
    regexes_len="$(echo -e ${expected_metrics} | grep -A 2 "${metric_name}$" | grep regex | wc -l)"
    if [[ "${regexes_len}" -eq "2" ]]; then

      regex_1_0="$(get_release_regex "${metric_name}" '^\s+-' 'head')"
      regex_0_17="$(get_release_regex "${metric_name}" '^\s+\+' 'head')"
      regex="$(get_regex "${i}" "${j}")"
      if [[ "${regex_0_17}" = "${regex}" ]]; then
          yq w -i new.yaml -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
      else
          echo "Changes of regex for 'prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}]' (${metric_name}) detected, please migrate it manually"
          git --no-pager diff --no-index $(echo "${regex_0_17}" | git hash-object -w --stdin) $(echo "${regex}" | git hash-object -w --stdin)  --word-diff-regex='[^\|]'
      fi
    fi

    if [[ "${metric_name}" = "/prometheus.metrics.container" ]]; then
        regex_1_0="$(get_release_regex "${metric_name}" '^\s+-' 'head')"
        regex_0_17="$(get_release_regex "${metric_name}" '^\s+\+' 'head')"
        regex="$(get_regex "${i}" "${j}")"
        if [[ "${regex_0_17}" = "${regex}" ]]; then
            yq w -i new.yaml -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
        else
            regex_1_0="$(get_release_regex "${metric_name}" '^\s+-' 'tail')"
            regex_0_17="$(get_release_regex "${metric_name}" '^\s+\+' 'tail')"
            if [[ "${regex_0_17}" = "${regex}" ]]; then
                yq w -i new.yaml -- "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
            else
                echo "Changes of regex for 'prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}]' (${metric_name}) detected, please migrate it manually"
            fi
        fi
    fi
done

# Fix fluent-bit env
if [[ ! -z "$(yq r new.yaml -- fluent-bit.env)" ]]; then
  yq w -i new.yaml -- "fluent-bit.env(name==CHART).valueFrom.configMapKeyRef.key" "fluentdLogs"
fi

# Fix prometheus service monitors
if [[ ! -z "$(yq r new.yaml -- prometheus-operator.prometheus.additionalServiceMonitors)" ]]; then
  yq d -i "new.yaml" -- "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE})"
  yq d -i "new.yaml" -- "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE}-otelcol)"
  yq d -i "new.yaml" -- "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE}-events)"
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
            app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-events" | yq m -a -i "new.yaml" -
fi

if [[ ! -z "$(yq r new.yaml -- prometheus-operator.prometheus.prometheusSpec.containers)" ]]; then
  yq w -i new.yaml -- "prometheus-operator.prometheus.prometheusSpec.containers(name==prometheus-config-reloader).env(name==CHART).valueFrom.configMapKeyRef.key" "fluentdMetrics"
fi

# Check user's image and echo warning if the image has been changed
readonly USER_VERSION="$(yq r ${OLD_VALUES_YAML} -- image.tag)"
if [[ ! -z "${USER_VERSION}" && "${USER_VERSION}" != "${PREVIOUS_VERSION}" ]]; then
  echo "You are using unsupported version: ${USER_VERSION}.
Please upgrade to ${PREVIOUS_VERSION} or ensure that new_values.yaml is valid"
fi

# New fluent-bit db path, and account for yq bug that stringifies empty maps
echo 'Replacing tail-db/tail-containers-state.db to tail-db/tail-containers-state-sumo.db'
echo 'Please ensure that new fluent-bit configuration is correct'

sed 's$tail-db/tail-containers-state.db$tail-db/tail-containers-state-sumo.db$g' new.yaml | \
sed "s/'{}'/{}/g" > new_values.yaml
rm new.yaml

DONE="Thank you for upgrading to v1.0.0 of the Sumo Logic Kubernetes Collection Helm chart.
A new yaml file has been generated for you. Please check the current directory for new_values.yaml."
echo "$DONE"
exit 0

OLD_CONFIGS="sumologic.eventCollectionEnabled
sumologic.events.sourceCategory
sumologic.logFormat
sumologic.flushInterval
sumologic.numThreads
sumologic.chunkLimitSize
sumologic.queueChunkLimitSize
sumologic.totalLimitSize
sumologic.sourceName
sumologic.sourceCategory
sumologic.sourceCategoryPrefix
sumologic.sourceCategoryReplaceDash
sumologic.addTimestamp
sumologic.timestampKey
sumologic.verifySsl
sumologic.excludeContainerRegex
sumologic.excludeHostRegex
sumologic.excludeNamespaceRegex
sumologic.excludePodRegex
sumologic.fluentdLogLevel
sumologic.watchResourceEventsOverrides
sumologic.fluentd.buffer
sumologic.fluentd.autoscaling.enabled
sumologic.fluentd.autoscaling.minReplicas
sumologic.fluentd.autoscaling.maxReplicas
sumologic.fluentd.autoscaling.targetCPUUtilizationPercentage
sumologic.fluentd.autoscaling.enabled
sumologic.fluentd.autoscaling.minReplicas
sumologic.fluentd.autoscaling.maxReplicas
sumologic.fluentd.autoscaling.targetCPUUtilizationPercentage
sumologic.k8sMetadataFilter.watch
sumologic.k8sMetadataFilter.verifySsl
sumologic.k8sMetadataFilter.cacheSize
sumologic.k8sMetadataFilter.cacheTtl
sumologic.k8sMetadataFilter.cacheRefresh
deployment.nodeSelector
deployment.tolerations
deployment.affinity
deployment.podAntiAffinity
deployment.replicaCount
deployment.resources.limits.memory
deployment.resources.limits.cpu
deployment.resources.requests.memory
deployment.resources.requests.cpu
deployment.nodeSelector
deployment.tolerations
deployment.affinity
deployment.podAntiAffinity
deployment.replicaCount
deployment.resources.limits.memory
deployment.resources.limits.cpu
deployment.resources.requests.memory
deployment.resources.requests.cpu
eventsDeployment.nodeSelector
eventsDeployment.tolerations
eventsDeployment.resources.limits.memory
eventsDeployment.resources.limits.cpu
eventsDeployment.resources.requests.memory
eventsDeployment.resources.requests.cpu"

NEW_CONFIGS="fluentd.events.enabled
fluentd.events.sourceCategory
fluentd.logs.output.logFormat
fluentd.buffer.flushInterval
fluentd.buffer.numThreads
fluentd.buffer.chunkLimitSize
fluentd.buffer.queueChunkLimitSize
fluentd.buffer.totalLimitSize
fluentd.logs.containers.sourceName
fluentd.logs.containers.sourceCategory
fluentd.logs.containers.sourceCategoryPrefix
fluentd.logs.containers.sourceCategoryReplaceDash
fluentd.logs.output.addTimestamp
fluentd.logs.output.timestampKey
fluentd.verifySsl
fluentd.logs.containers.excludeContainerRegex
fluentd.logs.containers.excludeHostRegex
fluentd.logs.containers.excludeNamespaceRegex
fluentd.logs.containers.excludePodRegex
fluentd.logLevel
fluentd.events.watchResourceEventsOverrides
fluentd.buffer.type
fluentd.logs.autoscaling.enabled
fluentd.logs.autoscaling.minReplicas
fluentd.logs.autoscaling.maxReplicas
fluentd.logs.autoscaling.targetCPUUtilizationPercentage
fluentd.metrics.autoscaling.enabled
fluentd.metrics.autoscaling.minReplicas
fluentd.metrics.autoscaling.maxReplicas
fluentd.metrics.autoscaling.targetCPUUtilizationPercentage
fluentd.logs.containers.k8sMetadataFilter.watch
fluentd.logs.containers.k8sMetadataFilter.verifySsl
fluentd.metadata.cacheSize
fluentd.metadata.cacheTtl
fluentd.metadata.cacheRefresh
fluentd.logs.statefulset.nodeSelector
fluentd.logs.statefulset.tolerations
fluentd.logs.statefulset.affinity
fluentd.logs.statefulset.podAntiAffinity
fluentd.logs.statefulset.replicaCount
fluentd.logs.statefulset.resources.limits.memory
fluentd.logs.statefulset.resources.limits.cpu
fluentd.logs.statefulset.resources.requests.memory
fluentd.logs.statefulset.resources.requests.cpu
fluentd.metrics.statefulset.nodeSelector
fluentd.metrics.statefulset.tolerations
fluentd.metrics.statefulset.affinity
fluentd.metrics.statefulset.podAntiAffinity
fluentd.metrics.statefulset.replicaCount
fluentd.metrics.statefulset.resources.limits.memory
fluentd.metrics.statefulset.resources.limits.cpu
fluentd.metrics.statefulset.resources.requests.memory
fluentd.metrics.statefulset.resources.requests.cpu
fluentd.events.statefulset.nodeSelector
fluentd.events.statefulset.tolerations
fluentd.events.statefulset.resources.limits.memory
fluentd.events.statefulset.resources.limits.cpu
fluentd.events.statefulset.resources.requests.memory
fluentd.events.statefulset.resources.requests.cpu"

CLEANUP_CONFIGS="sumologic.events
sumologic.fluentd
sumologic.k8sMetadataFilter
sumologic.kubernetesMeta
sumologic.kubernetesMetaReduce
sumologic.addStream
sumologic.addTime
deployment
eventsDeployment
fluentd.statefulset
fluentd.autoscaling
fluentd.rawConfig"

IFS=$'\n' read -r -d '' -a OLD_CONFIGS <<< "$OLD_CONFIGS"
IFS=$'\n' read -r -d '' -a NEW_CONFIGS <<< "$NEW_CONFIGS"
IFS=$'\n' read -r -d '' -a CLEANUP_CONFIGS <<< "$CLEANUP_CONFIGS"

# Override new values.yaml with old configs
yq m -i -x new.yaml $OLD_VALUES_YAML

# Write values of old configs to renamed configs
# Then delete old configs from new values.yaml
for i in ${!OLD_CONFIGS[@]}; do
  yq w -i new.yaml ${NEW_CONFIGS[$i]} "$(yq r $OLD_VALUES_YAML ${OLD_CONFIGS[$i]})"
  yq d -i new.yaml ${OLD_CONFIGS[$i]}
done

#exit 0


##########################################
# Special case for fluentd.events.WatchResourceEventsOverrides
# as this config is commented out by default but we will write it as empty string
# which will not work
if [ "$(yq r $OLD_VALUES_YAML sumologic.watchResourceEventsOverrides)" = "" ]; then
  yq d -i new.yaml fluentd.events.watchResourceEventsOverrides
fi


##########################################
# Keep image version as 1.0.0
yq w -i new.yaml image.tag 1.0.0


##########################################
# Keep pre-upgrade hook
PRE_UPGRADE="clusterRole
clusterRoleBinding
configMap
job
serviceAccount"
IFS=$'\n' read -r -d '' -a PRE_UPGRADE <<< "$PRE_UPGRADE"
for i in ${!PRE_UPGRADE[@]}; do
  yq w -i new.yaml sumologic.setup.${PRE_UPGRADE[$i]}.annotations[helm.sh/hook] pre-install,pre-upgrade
done


##########################################
# Keep Falco disabled
yq w -i new.yaml falco.enabled false


##########################################
# Preserve the functionality of addStream=false or addTime=false
if [ "$(yq r $OLD_VALUES_YAML sumologic.addStream)" != "true" ] && [ "$(yq r $OLD_VALUES_YAML sumologic.addTime)" != "true" ]; then
  REMOVE="stream,time"
elif [ "$(yq r $OLD_VALUES_YAML sumologic.addStream)" != "true" ]; then
  REMOVE="stream"
elif [ "$(yq r $OLD_VALUES_YAML sumologic.addTime)" != "true" ]; then
  REMOVE="time"
fi

FILTER="<filter containers.**>
  @type record_modifier
  remove_keys $REMOVE
</filter>"

if [ "$(yq r $OLD_VALUES_YAML sumologic.addStream)" != "true" ] || [ "$(yq r $OLD_VALUES_YAML sumologic.addTime)" != "true" ]; then
  yq w -i new.yaml fluentd.logs.containers.extraFilterPluginConf "$FILTER"
fi

##########################################
# Prometheus changes
# Diff of prometheus regexes:
# git diff v1.0.0 v0.17.1 deploy/helm/sumologic/values.yaml | \
# grep -E '(regex|url)\:' | \
# grep -E "^(\-|\+)\s+ (regex|url)\:" | \
# sed 's|-        url: http://$(CHART).$(NAMESPACE).svc.cluster.local:9888||' | \
# sed 's/$/\\n/'
#
# minus means 1.0.0 regex
# plus means 0.17.1 regex

expected_metrics="/prometheus.metrics.state\n
-          regex: kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_deployment_spec_replicas|kube_deployment_status_replicas_available|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)\n
+          regex: kube-state-metrics;(?:kube_statefulset_status_observed_generation|kube_statefulset_status_replicas|kube_statefulset_replicas|kube_statefulset_metadata_generation|kube_daemonset_status_current_number_scheduled|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_number_misscheduled|kube_daemonset_status_number_unavailable|kube_daemonset_metadata_generation|kube_deployment_metadata_generation|kube_deployment_spec_paused|kube_deployment_spec_replicas|kube_deployment_spec_strategy_rollingupdate_max_unavailable|kube_deployment_status_replicas_available|kube_deployment_status_observed_generation|kube_deployment_status_replicas_unavailable|kube_node_info|kube_node_spec_unschedulable|kube_node_status_allocatable|kube_node_status_capacity|kube_node_status_condition|kube_pod_container_info|kube_pod_container_resource_requests|kube_pod_container_resource_limits|kube_pod_container_status_ready|kube_pod_container_status_terminated_reason|kube_pod_container_status_waiting_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase)\n
/prometheus.metrics.controller-manager\n
/prometheus.metrics.scheduler\n
/prometheus.metrics.apiserver\n
-          regex: apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_(?:duration_seconds|latencies)_(?:count|sum)|apiserver_request_latencies_summary(?:|_count|_sum)|etcd_request_cache_(?:add|get)_(?:duration_seconds|latencies_summary)_(?:count|sum)|etcd_helper_cache_(?:hit|miss)_(?:count|total))\n
+          regex: apiserver;(?:apiserver_request_(?:count|total)|apiserver_request_latenc(?:ies|y_seconds).*|etcd_request_cache_get_latenc(?:ies_summary|y_seconds).*|etcd_request_cache_add_latenc(?:ies_summary|y_seconds).*|etcd_helper_cache_hit_(?:count|total)|etcd_helper_cache_miss_(?:count|total))\n
/prometheus.metrics.kubelet\n
-          regex: kubelet;(?:kubelet_docker_operations_errors(?:|_total)|kubelet_(?:docker|runtime)_operations_duration_seconds_(?:count|sum)|kubelet_running_(?:container|pod)_count|kubelet_(:?docker|runtime)_operations_latency_microseconds(?:|_count|_sum))\n
+          regex: kubelet;(?:kubelet_docker_operations_errors|kubelet_docker_operations_latency_microseconds|kubelet_running_container_count|kubelet_running_pod_count|kubelet_runtime_operations_latency_microseconds.*)\n
/prometheus.metrics.container\n
-          regex: kubelet;.+;(?:container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_fs_usage_bytes|container_fs_limit_bytes)\n
+          regex: kubelet;.+;(?:container_cpu_load_average_10s|container_cpu_system_seconds_total|container_cpu_usage_seconds_total|container_cpu_cfs_throttled_seconds_total|container_memory_usage_bytes|container_memory_swap|container_memory_working_set_bytes|container_spec_memory_limit_bytes|container_spec_memory_swap_limit_bytes|container_spec_memory_reservation_limit_bytes|container_spec_cpu_quota|container_spec_cpu_period|container_fs_usage_bytes|container_fs_limit_bytes|container_fs_reads_bytes_total|container_fs_writes_bytes_total|)\n
/prometheus.metrics.container\n
-          regex: kubelet;(?:container_network_receive_bytes_total|container_network_transmit_bytes_total)\n
+          regex: kubelet;(?:container_network_receive_bytes_total|container_network_transmit_bytes_total|container_network_receive_errors_total|container_network_transmit_errors_total|container_network_receive_packets_dropped_total|container_network_transmit_packets_dropped_total)\n
/prometheus.metrics.node\n
-          regex: node-exporter;(?:node_load1|node_load5|node_load15|node_cpu_seconds_total)\n
+          regex: node-exporter;(?:node_load1|node_load5|node_load15|node_cpu_seconds_total|node_memory_MemAvailable_bytes|node_memory_MemTotal_bytes|node_memory_Buffers_bytes|node_memory_SwapCached_bytes|node_memory_Cached_bytes|node_memory_MemFree_bytes|node_memory_SwapFree_bytes|node_ipvs_incoming_bytes_total|node_ipvs_outgoing_bytes_total|node_ipvs_incoming_packets_total|node_ipvs_outgoing_packets_total|node_disk_reads_completed_total|node_disk_writes_completed_total|node_disk_read_bytes_total|node_disk_written_bytes_total|node_filesystem_avail_bytes|node_filesystem_free_bytes|node_filesystem_size_bytes|node_filesystem_files)\n
/prometheus.metrics.operator.rule\n
-          regex: 'cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:'\n
+          regex: 'cluster_quantile:apiserver_request_latencies:histogram_quantile|instance:node_cpu:rate:sum|instance:node_filesystem_usage:sum|instance:node_network_receive_bytes:rate:sum|instance:node_network_transmit_bytes:rate:sum|instance:node_cpu:ratio|cluster:node_cpu:sum_rate5m|cluster:node_cpu:ratio|cluster_quantile:scheduler_e2e_scheduling_latency:histogram_quantile|cluster_quantile:scheduler_scheduling_algorithm_latency:histogram_quantile|cluster_quantile:scheduler_binding_latency:histogram_quantile|node_namespace_pod:kube_pod_info:|:kube_pod_info_node_count:|node:node_num_cpu:sum|:node_cpu_utilisation:avg1m|node:node_cpu_utilisation:avg1m|node:cluster_cpu_utilisation:ratio|:node_cpu_saturation_load1:|node:node_cpu_saturation_load1:|:node_memory_utilisation:|:node_memory_MemFreeCachedBuffers_bytes:sum|:node_memory_MemTotal_bytes:sum|node:node_memory_bytes_available:sum|node:node_memory_bytes_total:sum|node:node_memory_utilisation:ratio|node:cluster_memory_utilisation:ratio|:node_memory_swap_io_bytes:sum_rate|node:node_memory_utilisation:|node:node_memory_utilisation_2:|node:node_memory_swap_io_bytes:sum_rate|:node_disk_utilisation:avg_irate|node:node_disk_utilisation:avg_irate|:node_disk_saturation:avg_irate|node:node_disk_saturation:avg_irate|node:node_filesystem_usage:|node:node_filesystem_avail:|:node_net_utilisation:sum_irate|node:node_net_utilisation:sum_irate|:node_net_saturation:sum_irate|node:node_net_saturation:sum_irate|node:node_inodes_total:|node:node_inodes_free:'\n
/prometheus.metrics\n"

function get_regex() {
    # Get regex from old yaml file and strip `'` and `"` from beginning/end of it
    local write_index="${1}"
    local relabel_index="${2}"
    yq r "${OLD_VALUES_YAML}" "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${write_index}].writeRelabelConfigs[${relabel_index}].regex" | sed -e "s/^'//" -e 's/^"//' -e "s/'$//" -e 's/"$//'
}

function get_release_regex() {
  local metric_name="${1}"
  local str_grep="${2}"
  local filter="${3}"

  echo -e ${expected_metrics} | grep -A 3 "${metric_name}$" | "${filter}" -n 3 | grep -E "${str_grep}" | grep -oE ': .*' | sed 's/: //' | sed -e "s/^'//" -e 's/^"//' -e "s/'$//" -e 's/"$//'
}

metrics_length="$(yq r -l "${OLD_VALUES_YAML}" 'prometheus-operator.prometheus.prometheusSpec.remoteWrite')"
metrics_length="$(( ${metrics_length} - 1))"

for i in $(seq 0 ${metrics_length}); do
    metric_name="$(yq r "${OLD_VALUES_YAML}" "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].url" | grep -oE '/prometheus\.metrics.*')"
    metric_regex_length="$(yq r -l "${OLD_VALUES_YAML}" "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs")"
    metric_regex_length="$(( ${metric_regex_length} - 1))"

    for j in $(seq 0 ${metric_regex_length}); do
        metric_regex_action=$(yq r "${OLD_VALUES_YAML}" "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].action")
        if [[ "${metric_regex_action}" = "keep" ]]; then
            break
        fi
    done
    regexes_len="$(echo -e ${expected_metrics} | grep -A 2 "${metric_name}$" | grep regex | wc -l)"
    if [[ "${regexes_len}" -eq "2" ]]; then

      regex_1_0="$(get_release_regex "${metric_name}" '^\s+-' 'head')"
      regex_0_17="$(get_release_regex "${metric_name}" '^\s+\+' 'head')"
      regex="$(get_regex "${i}" "${j}")"
      if [[ "${regex_0_17}" = "${regex}" ]]; then
          yq w -i new.yaml "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
      else
          echo "Changes of regex for 'prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}]' (${metric_name}) detected, please migrate it manually"
          git --no-pager diff --no-index $(echo "${regex_0_17}" | git hash-object -w --stdin) $(echo "${regex}" | git hash-object -w --stdin)  --word-diff-regex='[^\|]'
      fi
    fi

    if [[ "${metric_name}" = "/prometheus.metrics.container" ]]; then
        regex_1_0="$(get_release_regex "${metric_name}" '^\s+-' 'head')"
        regex_0_17="$(get_release_regex "${metric_name}" '^\s+\+' 'head')"
        regex="$(get_regex "${i}" "${j}")"
        if [[ "${regex_0_17}" = "${regex}" ]]; then
            yq w -i new.yaml "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
        else
            regex_1_0="$(get_release_regex "${metric_name}" '^\s+-' 'tail')"
            regex_0_17="$(get_release_regex "${metric_name}" '^\s+\+' 'tail')"
            if [[ "${regex_0_17}" = "${regex}" ]]; then
                yq w -i new.yaml "prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}].regex" "${regex_1_0}"
            else
                echo "Changes of regex for 'prometheus-operator.prometheus.prometheusSpec.remoteWrite[${i}].writeRelabelConfigs[${j}]' (${metric_name}) detected, please migrate it manually"
            fi
        fi
    fi
done

# Fix fluent-bit env
yq w -i new.yaml "fluent-bit.env(name==CHART).valueFrom.configMapKeyRef.key" "fluentdLogs"

# Fix prometheus service monitors
yq d -i "new.yaml" "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE})"
yq d -i "new.yaml" "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE}-otelcol)"
yq d -i "new.yaml" "prometheus-operator.prometheus.additionalServiceMonitors(name==${HELM_RELEASE_NAME}-${NAMESPACE}-events)"
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
            app: ${HELM_RELEASE_NAME}-${NAMESPACE}-fluentd-events" | yq m -a -i "new.yaml" -

yq w -i new.yaml "prometheus-operator.prometheus.prometheusSpec.containers(name==prometheus-config-reloader).env(name==CHART).valueFrom.configMapKeyRef.key" "fluentdMetrics"


# Delete leftover old configs from new values.yaml
for c in ${CLEANUP_CONFIGS[@]}; do
  yq d -i new.yaml $c
done


##########################################
# New fluent-bit db path, and account for yq bug that stringifies empty maps
sed "s/tail-db\/tail-containers-state.db/tail-db\/tail-containers-state-sumo.db/g" new.yaml | \
sed "s/'{}'/{}/g" > new_values.yaml
rm new.yaml

DONE="Thank you for upgrading to v1.0.0 of the Sumo Logic Kubernetes Collection Helm chart.
A new yaml file has been generated for you. Please check the current directory for new_values.yaml."
echo "$DONE"
