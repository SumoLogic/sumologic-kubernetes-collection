# Kubernetes Collection 1.0.0 - Breaking Changes

<!-- TOC -->

- [Helm Users](#helm-users)
  - [Changes](#changes)
  - [How to upgrade](#how-to-upgrade)
    - [1. Upgrade to helm chart version v0.17.4](#1-upgrade-to-helm-chart-version-v0174)
    - [2. Run upgrade script](#2-run-upgrade-script)
  - [Rollback](#rollback)
- [Non-Helm Users](#non-helm-users)
  - [Changes](#breaking-changes)
  - [How to upgrade](#how-to-upgrade-for-non-helm-users)
    - [1. Tear down existing collection resources](#1-tear-down-existing-fluentd-prometheus-fluent-bit-resources)
    - [2. Deploy New Resources](#2-deploy-fluentd-fluent-bit-and-prometheus-again-with-the-version-100-yaml)
      - [2.1: Deploy Fluentd](#21-deploy-fluentd)
      - [2.1: Deploy Prometheus](#22-deploy-prometheus)
      - [2.1: Deploy Fluent Bit](#23-deploy-fluent-bit)


<!-- /TOC -->

Based on the feedback from our users, we will be introducing several changes to the Sumo Logic Kubernetes Collection solution. Here we detail the changes for both Helm and Non-Helm users, as well as the exact steps for migration.
## Helm Users
### Changes

- Falco installation disabled by Default. If you want to enable Falco, modify the `enabled` flag for Falco in `values.yaml` as shown below:
```yaml
falco:
  ## Set the enabled flag to false to disable falco.
  enabled: true
  ```

- Bumped the helm Falco chart version to v`1.1.6` which included a fix to disable the bitcoin/crypto miner rule by default

- Changes in Configuration Parameters
	- The `values.yaml` file has had several configs moved and renamed to improve usability. Namely, we introduced a new fluentd section into which we moved all of the Fluentd specific configs, while configs for our dependency charts (`prometheus-operator`, `fluent-bit`, `metrics-server`, `falco`) have not changed.

| Old Config 	| New Config 	|
|:----------------------------------------:	|:-----------------------------------------------------:	|
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
| sumologic.fluentd.autoscaling.* 	| fluentd.logs.autoscaling.* , fluentd.metrics.autoscaling.* 	|
| sumologic.k8sMetadataFilter.watch 	| fluentd.logs.containers.k8sMetadataFilter.watch 	|
| sumologic.k8sMetadataFilter.verifySsl 	| fluentd.logs.containers.k8sMetadataFilter.verifySsl 	|
| sumologic.k8sMetadataFilter.cacheSize 	| fluentd.metadata.cacheSize 	|
| sumologic.k8sMetadataFilter.cacheTtl 	| fluentd.metadata.cacheTtl 	|
| sumologic.k8sMetadataFilter.cacheRefresh 	| fluentd.metadata.cacheRefresh 	|
| deployment.* 	| fluentd.logs.statefulset.* , fluentd.metrics.statefulset.*	|
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

You can look for example configurations [here](../docs/v1_conf_examples.md)

The Fluentd `deployments` have been changed to `statefulsets` to support the use of persistent volumes. This will allow better buffering behavior. They also now include `“fluentd”` in their names. This is not a breaking change for Helm users.

The unified Fluentd `statefulsets` have been split into set of two different Fluentd's, one for `logs` and the other one for `metrics`.

### How to upgrade
**Note: The below steps are using Helm 2. Helm 3 is not supported.**
#### 1. Upgrade to helm chart version `v0.17.4`

Run the below command to fetch the latest helm chart:
```bash
helm repo update
```

For the users who are not already on `v0.17.4` of the helm chart, please upgrade to that version first by running the below command.

```bash
helm upgrade collection sumologic/sumologic --reuse-values --version=0.17.4
```
#### 2: Run upgrade script

For Helm users, the only breaking changes are the renamed config parameters.
For users who use a `values.yaml` file, we provide a script that users can run to convert their existing `values.yaml` file into one that is compatible with the major release.


- Get the existing values for the helm chart and store it as `current_values.yaml` with the below command:
```bash
helm get values <RELEASE-NAME> > current_values.yaml
```
- Run `curl` the upgrade script as follows:
```bash
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v1.0/deploy/helm/sumologic/upgrade-1.0.0.sh
```
- Run the upgrade script on the above file with the below command.
```bash
./upgrade-1.0.0.sh current_values.yaml
```
- At this point, users can then run:
```bash
helm upgrade collection sumologic/sumologic --version=1.0.0 -f new_values.yaml
```

### Troubleshooting Upgrade
If you receive the below error, it likely means your OS is picking up an older version of `bash` even though you may have upgraded.  Makes sure you are running a version of `bash` >= 4.4 by running `bash --version`.  If the version of bash is correct, you can rerun the upgrade script by running `bash upgrade-1.0.0.sh current_values.yaml` and then rerun `helm upgrade collection sumologic/sumologic --version=1.0.0 -f new_values.yaml` to resolve.

```Error: UPGRADE FAILED: error validating "": error validating data: [ValidationError(StatefulSet.spec.template.spec.containers[0].resources.limits.cpu fluentd): invalid type for io.k8s.apimachinery.pkg.api.resource.Quantity: got "map", expected "string", ValidationError(StatefulSet.spec.template.spec.containers[0].resources.limits.memory fluentd): invalid type for io.k8s.apimachinery.pkg.api.resource.Quantity: got "map", expected "string", ValidationError(StatefulSet.spec.template.spec.containers[0].resources.requests.cpu fluentd): invalid type for io.k8s.apimachinery.pkg.api.resource.Quantity: got "map", expected "string", ValidationError(StatefulSet.spec.template.spec.containers[0].resources.requests.memory fluentd): invalid type for io.k8s.apimachinery.pkg.api.resource.Quantity: got "map", expected "string"]```

### Rollback

If something goes wrong, or you want to go back to the previous version,
you can [rollback changes using helm](https://v2.helm.sh/docs/helm/#helm-rollback):

```
helm history collection
helm rollback collection <REVISION-NUMBER>
```

## Non-Helm Users
### Breaking Changes
- The use of environment variables to set configs has been removed to avoid the extra layer of indirection and confusion. Instead, configs will be set directly within the Fluentd pipeline.
- `kubernetesMeta` and `kubernetesMetaReduce` have been removed from `logs.kubernetes.sumologic.filter.conf` of the Fluentd pipeline for the same reason as above (Helm users)
- Similarly `addStream` and `addTime` (default values were `true`) have been removed from `logs.kubernetes.sumologic.filter.conf` of the Fluentd pipeline; the default behavior will remain the same. To preserve the behavior of `addStream = false` or `addTime = false`, you can add:
```yaml
<filter containers.**>
  @type record_modifier
  remove_keys stream,time
</filter>
```
above the output plugin section [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v1.0/deploy/kubernetes/fluentd-sumologic.yaml.tmpl#L251)
- The Fluentd deployments have been changed to **statefulsets** to support the use of **persistent volumes**. This will allow better buffering behavior. They also now include `“fluentd”` in their names. This is a breaking change for non-Helm users as the deployments will not be cleaned up upon upgrade, leading to duplicate events (logs and metrics will not experience data duplication).
- The unified Fluentd `statefulsets` have been split into set of two different Fluentd's, one for `logs` and the other one for `metrics`.
- We now support the collection of renamed metrics (for Kubernetes version `1.17+`).
### How to upgrade for Non-helm Users
#### 1. Tear down existing Fluentd, Prometheus, Fluent Bit and Falco resources
You will need the YAML files you created when you first installed collection. Run the following commands to remove Falco, Fluent-bit, Prometheus Operator and FluentD.  You do not need to delete the Namespace and Secret you originally created as they will still be used.

```sh
kubectl delete -f falco.yaml
kubectl delete -f fluent-bit.yaml
kubectl delete -f prometheus.yaml
kubectl delete -f fluentd-sumologic.yaml
```

#### 2. Deploy Fluentd, Fluent Bit and Prometheus again with the version 1.0.0 yaml
Follow the below steps to deploy new resources.
##### 2.1 Deploy Fluentd
- Non-Helm users who have made changes to configs in the [environment variable sections](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v0.17/deploy/kubernetes/fluentd-sumologic.yaml.tmpl#L627-L678) of the `fluentd-sumologic.yaml` file will need to move those config changes directly into the Fluentd pipeline.

- Run the below command to get the `fluentd-sumologic.yaml` manifest for version `v1.0.0` and  then make the changes identified in the above step.
```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v1.0/deploy/kubernetes/fluentd-sumologic.yaml.tmpl | \
sed 's/\$NAMESPACE'"/<NAMESPACE>/g" | \
sed 's/cluster kubernetes/cluster <CLUSTER_NAME>/g'  >> fluentd-sumologic.yaml
```

- Non-Helm users running a Kubernetes version of 1.13 or older will need to **remove the following filter plugin section from their Fluentd pipeline. This is required to prevent data duplication.**
```yaml
<filter prometheus.metrics**> # NOTE: Remove this filter if you are running Kubernetes 1.13 or below.
  @type grep
  <exclude>
    key @metric
    pattern /^apiserver_request_count|^apiserver_request_latencies_summary|^kubelet_runtime_operations_latency_microseconds|^kubelet_docker_operations_latency_microseconds|^kubelet_docker_operations_errors$/
  </exclude>
</filter>
```
##### 2.2 Deploy Prometheus
- Follow steps mentioned [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/docs/Non_Helm_Installation.md#deploy-prometheus) to deploy Prometheus.
##### 2.3: Deploy Fluent Bit
- Follow steps mentioned [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/docs/Non_Helm_Installation.md#deploy-fluentbit) to deploy Fluent Bit.
