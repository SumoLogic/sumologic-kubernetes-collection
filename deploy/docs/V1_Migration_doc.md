# Kubernetes Collection 1.0.0 - Breaking Changes
Based on the feedback from our users, we will be introducing several changes to the Sumo Logic Kubernetes Collection solution. Here we detail the changes for both Helm and Non-Helm users, as well as the exact steps for migration.
## Helm Users
### Changes

- Falco installation disabled by Default

- Changes in Configuration Parameters
	- The `values.yaml` file has had several configs moved and renamed to improve usability. Namely, we introduced a new fluentd section into which we moved all of the Fluentd specific configs, while configs for our dependency charts (`prometheus-operator`, `fluent-bit`, `metrics-server`, `falco`) have not changed.

| Old Config 	| New Config 	|
|:----------------------------------------:	|-----------------------------------------------------	|
| sumologic.eventCollectionEnabled 	| fluentd.events.enabled 	|
| sumologic.events.sourceCategory 	| fluentd.events.sourceCategory 	|
| sumologic.logFormat 	| fluentd.logs.output.logFormat 	|
| sumologic.flushInterval 	| fluentd.buffer.flushInterval 	|
| sumologic.numThreads 	| fluentd.buffer.numThreads 	|
| sumologic.chunkLimitSize 	| fluentd.buffer.chunkLimitSize 	|
| sumologic.queueChunkLimitSize 	| fluentd.buffer.queueChunkLimitSize 	|
| sumologic.totalLimitSize 	| fluentd.buffer.totalLimitSize 	|
| sumologic.sourceName 	| fluentd.logs.containers.sourceName 	|
| sumologic.sourceCategory 	| fluentd.logs.containers.sourceCategory 	|
| sumologic.sourceCategoryPrefix 	| fluentd.logs.containers.sourceCategoryPrefix 	|
| sumologic.sourceCategoryReplaceDash 	| fluentd.logs.containers.sourceCategoryReplaceDash 	|
| sumologic.addTimestamp 	| fluentd.logs.output.addTimestamp 	|
| sumologic.timestampKey 	| fluentd.logs.output.timestampKey 	|
| sumologic.verifySsl 	| fluentd.verifySsl 	|
| sumologic.excludeContainerRegex 	| fluentd.logs.containers.excludeContainerRegex 	|
| sumologic.excludeHostRegex 	| fluentd.logs.containers.excludeHostRegex 	|
| sumologic.excludeNamespaceRegex 	| fluentd.logs.containers.excludeNamespaceRegex 	|
| sumologic.excludePodRegex 	| fluentd.logs.containers.excludePodRegex 	|
| sumologic.fluentdLogLevel 	| fluentd.logLevel 	|
| sumologic.watchResourceEventsOverrides 	| fluentd.events.watchResourceEventsOverrides 	|
| sumologic.fluentd.buffer 	| fluentd.buffer.type 	|
| sumologic.fluentd.autoscaling.* 	| fluentd.autoscaling.* 	|
| sumologic.k8sMetadataFilter.watch 	| fluentd.logs.containers.k8sMetadataFilter.watch 	|
| sumologic.k8sMetadataFilter.verifySsl 	| fluentd.logs.containers.k8sMetadataFilter.verifySsl 	|
| sumologic.k8sMetadataFilter.cacheSize 	| fluentd.metadata.cacheSize 	|
| sumologic.k8sMetadataFilter.cacheTtl 	| fluentd.metadata.cacheTtl 	|
| sumologic.k8sMetadataFilter.cacheRefresh 	| fluentd.metadata.cacheRefresh 	|
| deployment.* 	| fluentd.statefulset.* 	|
| eventsDeployment.* 	| fluentd.eventsStatefulset.* 	|


   - `sumologic.kubernetesMeta` and `sumologic.kubernetesMetaReduce` have been removed. The default log format (`fluentd.logs.output.logFormat`) is `fields`, which removes the relevant metadata from the JSON body of the logs, making these configs no longer necessary.
   - `sumologic.addStream` and `sumologic.addTime` (default values were `true`) have been removed; the default behavior will remain the same. To preserve the behavior of `addStream = false` or `addTime = false`, you can add the following config to the `values.yaml` file:

```yaml
fluentd:
  logs:
    containers:
      extraFilterPluginConf:
        <filter **>
          @type record_modifier
          remove_keys stream, time
        </filter>
```

Until now, Helm users have not been able to modify their Fluentd configuration outside of the specific parameters that we exposed in the `values.yaml` file. Now, we expose the ability to modify the Fluentd configuration as needed. 

Some use-cases include : 
 - custom log pipelines, 
 - adding Fluentd filter plugins (ex: fluentd throttle plugin), or 
 - adding Fluentd output plugins (ex: forward to both Sumo and S3)

The Fluentd deployments have been changed to statefulsets to support the use of persistent volumes. This will allow better buffering behavior. They also now include `“fluentd”` in their names. This is not a breaking change for Helm users.


### How to upgrade
**Step 1**: If the user is not already on v0.17.1 of the helm chart, upgrade to that version first by running the below command.

- ```bash
helm upgrade collection sumologic/sumologic --reuse-values --version=0.17.1
```
**Step 2**: 

For Helm users, the only breaking changes are the renamed config parameters.
For users who use a `values.yaml` file, we will provide a script that customers can run to convert their existing `values.yaml` files into ones that are compatible with the major release. 

The upgrade script is present in the path : `sumologic-kubernetes-collection/deploy/helm/sumologic/`

Run the upgrade script with the below command.
```bash
./upgrade-1.0.0.sh values.yaml
```
At this point, users can then run: 
```bash
helm upgrade collection sumologic/sumologic --reuse-values --version=1.0.0 -f new_values.yaml
```
For users who installed without a `values.yaml` file, if they had set any of the above config parameters they will need to re-set those parameters during their upgrade. For example, if the customer had originally run
```bash
helm install sumologic/sumologic --name collection --namespace sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> ... --set sumologic.numThreads=16
```
Then their upgrade command will look like
```bash
helm upgrade collection sumologic/sumologic --reuse-values --version=1.0.0 --set fluentd.buffer.numThreads=16
```
## Non-Helm Users
### Changes
- The use of environment variables to set configs has been removed to avoid the extra layer of indirection and confusion. Instead, configs will be set directly within the Fluentd pipeline.
- `kubernetesMeta` and `kubernetesMetaReduce` have been removed from `logs.kubernetes.sumologic.filter.conf` of the Fluentd pipeline for the same reason as above (Helm users)
- Similarly `addStream` and `addTime` (default values were `true`) have been removed from `logs.kubernetes.sumologic.filter.conf` of the Fluentd pipeline; the default behavior will remain the same. To preserve the behavior of `addStream = false` or `addTime = false`, you can add: 
```yaml
<filter containers.**>
  @type record_modifier
  remove_keys stream,time
</filter>
```
above the output plugin section [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/kubernetes/fluentd-sumologic.yaml.tmpl#L251)
- The Fluentd deployments have been changed to **statefulsets** to support the use of **persistent volumes**. This will allow better buffering behavior. They also now include `“fluentd”` in their names. This is a breaking change for non-Helm users as the deployments will not be cleaned up upon upgrade, leading to duplicate events (logs and metrics will not experience data duplication).
- We now support the collection of renamed metrics (for Kubernetes version `1.17+`).
### How to upgrade
**Step 1**: 
- Non-Helm users who have made changes to configs in the environment variable sections of the fluentd-sumologic.yaml file will need to **move those config changes directly into the Fluentd pipeline.**
- Non-Helm users running a Kubernetes version of 1.13 or older will need to **remove the following filter plugin section from their Fluentd pipeline**
```yaml
<filter prometheus.metrics**> # NOTE: Remove this filter if you are running Kubernetes 1.13 or below.
  @type grep
  <exclude>
    key @metric
    pattern /^apiserver_request_count|^apiserver_request_latencies_summary|^kubelet_runtime_operations_latency_microseconds|^kubelet_docker_operations_latency_microseconds|^kubelet_docker_operations_errors$/
  </exclude>
</filter>
```
**Step 2**: 
- After making the above two changes, non-Helm users will need to run
```bash
kubectl apply -f fluentd-sumologic.yaml -n sumologic
```
followed by

```bash
kubectl delete deployment collection-sumologic -n sumologic
kubectl delete deployment collection-sumologic-events -n sumologic
```