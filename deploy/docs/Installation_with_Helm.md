# Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events;
enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

- [Requirements](#requirements)
- [Prerequisite](#prerequisite)
- [Installation Steps](#installation-steps)
  - [Authenticating with container registry](#authenticating-with-container-registry)
  - [Installing the helm chart in Openshift platform](#installing-the-helm-chart-in-openshift-platform)
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
- [Troubleshooting Installation](#troubleshooting-installation)
  - [Error: timed out waiting for the condition](#error-timed-out-waiting-for-the-condition)
  - [Error: collector with name 'sumologic' does not exist](#error-collector-with-name-sumologic-does-not-exist)
- [Customizing Installation](#customizing-installation)
- [Upgrading Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)

## Requirements

If you don’t already have a Sumo account, you can create one by clicking
the Free Trial button on https://www.sumologic.com/.

The following are required to set up Sumo Logic's Kubernetes collection.

- An [Access ID and Access Key](https://help.sumologic.com/Manage/Security/Access-Keys) with
  [Manage Collectors](https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities#data-management) capability.
- Please review our [minimum requirements](../README.md#minimum-requirements) and [support matrix](../README.md#support-matrix)

To get an idea of the resources this chart will require to run on your cluster,
you can reference our [performance doc](./Performance.md).

### Kubernetes version

As of `2.0.0` we're supporting clusters with kubernetes in version `1.16` and up.

In case your cluster doesn't fullfil this requirement you might expect the following
error to show up when performing `helm install ...`/`helm upgrade ...` steps:

```
...
Release "collection" does not exist. Installing it now.
Error: template: sumologic/templates/checks.txt:4:4: executing "sumologic/templates/checks.txt" at <fail "\nAt least k8s 1.16 is required. Please update your k8s version or set sumologic.setup.force to true">: error calling fail:
At least k8s 1.16 is required. Please update your k8s version or set sumologic.setup.force to true
```

## Prerequisite

Sumo Logic Apps for Kubernetes and Explore require below listed fields to be added
in Sumo Logic UI to your Fields table schema.

- `cluster`
- `container`
- `deployment`
- `host`
- `namespace`
- `node`
- `pod`
- `service`

This is normally done in the setup job when `sumologic.setupEnabled` is set
to `true` (default behavior).

In an unlikely scenario that this fails please create them manually by visiting
[Fields#Manage_fields](https://help.sumologic.com/Manage/Fields#Manage_fields)
in Sumo Logic UI.

This is to ensure your logs are tagged with relevant metadata.

This is a one time setup per Sumo Logic account.

## Installation Steps

These steps require that no Prometheus exists.
If you already have Prometheus installed select from the following options:

- [How to install our Chart side by side with your existing Prometheus Operator](./SideBySidePrometheus.md)
- [How to install if you have an existing Prometheus Operator you want to update](./existingPrometheusDoc.md)
- [How to install if you have standalone Prometheus (not using Prometheus Operator)](./standAlonePrometheus.md)

The Helm chart installation requires two parameter overrides:

- __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
- __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

If you are installing the collection in a cluster that requires proxying outbound requests,
please see the following [additional properties](./Installing_Behind_Proxy.md) you will need to set.

The following parameter is optional, but we recommend setting it.

- __sumologic.clusterName__ - An identifier for your Kubernetes cluster.
  This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can run `helm upgrade --install` to install our chart.
An example command with the minimum parameters is provided below.
The following command will install the Sumo Logic chart with the release name
`my-release` in the namespace your `kubectl` context is currently set to.

```bash
helm upgrade --install my-release sumologic/sumologic \
  --set sumologic.accessId="<SUMO_ACCESS_ID>" \
  --set sumologic.accessKey="<SUMO_ACCESS_KEY>" \
  --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

> **Note**: If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different existing namespace you can do the following:

```bash
helm upgrade --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  --set sumologic.accessId="<SUMO_ACCESS_ID>" \
  --set sumologic.accessKey="<SUMO_ACCESS_KEY>" \
  --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

If the namespace does not exist, you can add the `--create-namespace` flag.

```bash
helm upgrade --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  --create-namespace \
  --set sumologic.accessId="<SUMO_ACCESS_ID>" \
  --set sumologic.accessKey="<SUMO_ACCESS_KEY>" \
  --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

### Authenticating with container registry

Sumo Logic container images used in the collection are currently hosted
on [Docker Hub](https://hub.docker.com/) which
[requires authentication in order to provide higher quota for image pulls][docker-rate-limit].

Please refer to
[our instructions](/deploy/docs/Working_with_container_registries.md#authenticating-with-container-registry)
on how to provide credentials in order to authenticate with Docker Hub.

An alternative would be to host Sumo Logic container images in one's container
registries.
To do so please refer to the following
[instructions](/deploy/docs/Working_with_container_registries.md#hosting-sumo-logic-images)

[docker-rate-limit]: https://www.docker.com/increase-rate-limits

### Installing the helm chart in Openshift platform

The daemonset/statefulset fails to create the pods in Openshift environment due to
the request of elevated privileges, like HostPath mounts, privileged: true, etc.

If you wish to install the chart in the Openshift Platform, it requires a SCC resource
which is only created in Openshift (detected via API capabilities in the chart), you can do the following:

```bash
helm upgrade --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  --set sumologic.accessId="<SUMO_ACCESS_ID>" \
  --set sumologic.accessKey="<SUMO_ACCESS_KEY>" \
  --set sumologic.clusterName="<MY_CLUSTER_NAME>" \
  --set sumologic.scc.create=true \
  --set fluent-bit.securityContext.privileged=true
```

## Viewing Data In Sumo Logic

Once you have completed installation, you can
[install the Kubernetes App and view the dashboards][sumo-k8s-app-dashboards]
or [open a new Explore tab] in Sumo Logic.
If you do not see data in Sumo Logic, you can review our
[troubleshooting guide](./Troubleshoot_Collection.md).

[sumo-k8s-app-dashboards]: https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards
[open a new Explore tab]: https://help.sumologic.com/Observability_Solution/Kubernetes_Solution/Navigate_your_Kubernetes_environment

## Troubleshooting Installation

### Error: timed out waiting for the condition

If `helm upgrade --install` hangs, it usually means the pre-install setup job is failing and is in a retry loop.
Due to a Helm limitation, errors from the setup job cannot be fed back to the `helm upgrade --install` command.
Kubernetes schedules the job in a pod, so you can look at logs from the pod to see why the job is failing.
First find the pod name in the namespace where the Helm chart was deployed. The pod name will contain `-setup` in the name.

```sh
kubectl get pods
```

> **Tip**: If the pod does not exist, it is possible it has been evicted.
> Re-run the `helm upgrade --install` to recreate it and while that command is running,
> use another shell to get the name of the pod.

Get the logs from that pod:

```
kubectl logs POD_NAME -f
```

### Error: collector with name 'sumologic' does not exist

If you get

```
Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID
```

you can safely ignore it and the installation should complete successfully.
The installation process creates new [HTTP endpoints](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source)
in your Sumo Logic account, that are used to send data to Sumo.
This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

## Customizing Installation

All default properties for the Helm chart can be found in our [documentation](../helm/sumologic/README.md).
We recommend creating a new `values.yaml` for each Kubernetes cluster you wish
to install collection on and **setting only the properties you wish to override**.
Once you have customized you can use the following commands to install or upgrade.

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml
```

> **Tip**: To filter or add custom metrics to Prometheus,
> [please refer to this document](additional_prometheus_configuration.md)

## Upgrading Sumo Logic Collection

To upgrade our helm chart to a newer version, you must first run update your local helm repo.

```bash
helm repo update
```

Next, you can run `helm upgrade --install` to upgrade to that version.
The following upgrades the current version of `my-release` to the latest.

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml
```

If you wish to upgrade to a specific version, you can use the `--version` flag.

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml --version=2.0.0
```

If you no longer have your `values.yaml` from the first installation or do not remember
the options you added via `--set` you can run the following to see the values
for the currently installed helm chart.
For example, if the release is called `my-release` you can run the following.

```bash
helm get values my-release
```

If something goes wrong, or you want to go back to the previous version,
you can [rollback changes using helm](https://helm.sh/docs/helm/helm_rollback/):

```
helm history my-release
helm rollback my-release <REVISION-NUMBER>
```

## Uninstalling Sumo Logic Collection

To uninstall/delete the Helm chart:

```bash
helm delete my-release
```

> **Helm3 Tip**: In Helm3 the default behavior is to purge history.
> Use --keep-history to preserve it while deleting the release.

The command removes all the Kubernetes components associated with the chart and deletes the release.

### Post installation cleanup

In order to clean up the Kubernetes secret and associated hosted collector one
can use the optional cleanup job by setting `sumologic.cleanupEnabled` to `true`.

Alternatively the secret can be removed manually with:

```bash
kubectl delete secret sumologic
```

and the associated hosted collector can be deleted in the Sumo Logic UI.
