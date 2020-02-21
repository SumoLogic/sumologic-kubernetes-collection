#!/bin/bash

MAN="Thank you for upgrading to v1.0.0 of the Sumo Logic Kubernetes Collection Helm chart.
As part of this major release, the format of the values.yaml file has changed.

This script will automatically take the configurations of your existing values.yaml
and return one that is compatible with v1.0.0.

Usage:
  ./upgrade-1.0.0.sh /path/to/values.yaml

Returns:
  new.yaml

For more details, please refer to Migration steps and Changelog here: [link]
"

if [ "$1" = "" ]
then
  echo "$MAN"
  exit 1
fi

OLD_VALUES_YAML=$1

URL=https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/846cae152f4ccdc9cc1a26e4a67af1f603ea83fa/deploy/helm/sumologic/values.yaml
curl -s $URL > new.yaml

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
sumologic.k8sMetadataFilter.watch
sumologic.k8sMetadataFilter.verifySsl
sumologic.k8sMetadataFilter.cacheSize
sumologic.k8sMetadataFilter.cacheTtl
sumologic.k8sMetadataFilter.cacheRefresh"

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
fluentd.autoscaling.enabled
fluentd.autoscaling.minReplicas
fluentd.autoscaling.maxReplicas
fluentd.autoscaling.targetCPUUtilizationPercentage
fluentd.logs.containers.k8sMetadataFilter.watch
fluentd.logs.containers.k8sMetadataFilter.verifySsl
fluentd.metadata.cacheSize
fluentd.metadata.cacheTtl
fluentd.metadata.cacheRefresh"

CLEANUP_CONFIGS="sumologic.events
sumologic.fluentd
sumologic.k8sMetadataFilter
sumologic.kubernetesMeta
sumologic.kubernetesMetaReduce
sumologic.addStream
sumologic.addTime"

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

# Special case for fluentd.events.WatchResourceEventsOverrides
# as this config is commented out by default but we will write it as empty string
# which will not work
if [ "$(yq r $OLD_VALUES_YAML sumologic.watchResourceEventsOverrides)" = "" ]
then
  yq d -i new.yaml fluentd.events.watchResourceEventsOverrides
fi

# Keep image version as 1.0.0
yq w -i new.yaml image.tag 1.0.0

# Preserve the functionality of addStream=false or addTime=false
if [ $(yq r $OLD_VALUES_YAML sumologic.addStream) != "true" ] && [ $(yq r $OLD_VALUES_YAML sumologic.addTime) != "true" ]
then
  REMOVE="stream,time"
elif [ $(yq r $OLD_VALUES_YAML sumologic.addStream) != "true" ]
then
  REMOVE="stream"
elif [ $(yq r $OLD_VALUES_YAML sumologic.addTime) != "true" ]
then
  REMOVE="time"
fi

FILTER="<filter containers.**>
  @type record_modifier
  remove_keys $REMOVE
</filter>"

if [ $(yq r $OLD_VALUES_YAML sumologic.addStream) != "true" ] || [ $(yq r $OLD_VALUES_YAML sumologic.addTime) != "true" ]
then
  yq w -i new.yaml fluentd.logs.containers.extraFilterPluginConf "$FILTER"
fi

# Delete leftover old configs from new values.yaml
for c in ${CLEANUP_CONFIGS[@]}; do
  yq d -i new.yaml $c
done

DONE="Thank you for upgrading to v1.0.0 of the Sumo Logic Kubernetes Collection Helm chart.
A new yaml file has been generated for you. Please check the current directory for new.yaml."
echo "$DONE"
