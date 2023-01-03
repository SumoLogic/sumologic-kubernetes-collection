# Installation with Helm

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events;
enriching them with deployment, pod, and service level metadata; and sends them to Sumo Logic.

- [Requirements](#requirements)
  - [Kubernetes version](#kubernetes-version)
- [Prerequisite](#prerequisite)
- [Installation Steps](#installation-steps)
  - [Authenticating with container registry](#authenticating-with-container-registry)
  - [Installing the helm chart in Openshift platform](#installing-the-helm-chart-in-openshift-platform)
  - [Additional configuration settings](#additional-configuration-settings)
    - [Additional configuration for Kubernetes 1.25 or newer](#additional-configuration-for-kubernetes-125-or-newer)
    - [Additional configuration for AKS 1.25](#additional-configuration-for-aks-125)
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
- [Troubleshooting Installation](#troubleshooting-installation)
  - [Error: timed out waiting for the condition](#error-timed-out-waiting-for-the-condition)
  - [Error: collector with name 'sumologic' does not exist](#error-collector-with-name-sumologic-does-not-exist)
- [Customizing Installation](#customizing-installation)
- [Upgrading Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)
  - [Post installation cleanup](#post-installation-cleanup)
  - [Removing the kubelet Service](#removing-the-kubelet-service)

## Requirements

If you don’t already have a Sumo account, you can create one by clicking
the Free Trial button on https://www.sumologic.com/.

The following are required to set up Sumo Logic's Kubernetes collection.

- An [Access ID and Access Key](https://help.sumologic.com/docs/manage/security/access-keys/) with
  [Manage Collectors](https://help.sumologic.com/docs/manage/users-roles/roles/role-capabilities#data-management) capability.
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
[Fields#Manage_fields](https://help.sumologic.com/docs/manage/fields/#manage-fields)
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

- __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/docs/manage/security/access-keys/).
- __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/docs/manage/security/access-keys/).

If you are installing the collection in a cluster that requires proxying outbound requests,
please see the following [additional properties](./Installing_Behind_Proxy.md) you will need to set.

The following parameter is optional, but we recommend setting it.

- __sumologic.clusterName__ - An identifier for your Kubernetes cluster.
  This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.
  Whitespaces in the cluster name will be replaced with dashes.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can prepare `values.yaml` with configuration.
An example file with the minimum confiuration is provided below.

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
```

Now you can run `helm upgrade --install` to install our chart.
The following command will install the Sumo Logic chart with the release name `my-release`
in the namespace your `kubectl` context is currently set to.

```bash
helm upgrade --install my-release sumologic/sumologic \
  -f values.yaml
```

> __Note__: If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different existing namespace you can do the following:

```bash
helm upgrade --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  -f values.yaml
```

If the namespace does not exist, you can add the `--create-namespace` flag.

```bash
helm upgrade --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  --create-namespace \
  -f values.yaml
```

If you want to override the names of the resources created by the chart,
see [Overriding chart resource names with `fullnameOverride`](./Best_Practices.md#overriding-chart-resource-names-with-fullnameoverride).

### Authenticating with container registry

Sumo Logic container images used for collection are currently hosted on
[Amazon Public ECR][aws-public-ecr-docs] which requires authentication to provide
a higher quota for image pulls.
To find a comprehensive information on this please refer to
[Amazon Elastic Container Registry pricing][aws-ecr-pricing].

Please refer to
[our instructions](/deploy/docs/Working_with_container_registries.md#authenticating-with-container-registry)
on how to provide credentials in order to authenticate with Docker Hub.

An alternative would be to host Sumo Logic container images in one's container
registries.
To do so please refer to the following
[instructions](/deploy/docs/Working_with_container_registries.md#hosting-sumo-logic-images)

[aws-public-ecr-docs]: https://aws.amazon.com/blogs/aws/amazon-ecr-public-a-new-public-container-registry/
[aws-ecr-pricing]: https://aws.amazon.com/ecr/pricing/

### Installing the helm chart in Openshift platform

The daemonset/statefulset fails to create the pods in Openshift environment due to
the request of elevated privileges, like HostPath mounts, privileged: true, etc.

If you wish to install the chart in the Openshift Platform, it requires a SCC resource
which is only created in Openshift (detected via API capabilities in the chart),
you can add the following configuration to `values.yaml`:

```yaml
sumologic:
  scc:
    create: true
fluent-bit:
  securityContext:
    privileged: true
kube-prometheus-stack:
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
  prometheusOperator:
    namespaces:
      additional:
        - my-namespace
tailing-sidecar-operator:
  scc:
    create: true
```

so, it will look like the following:

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
  scc:
    create: true
fluent-bit:
  securityContext:
    privileged: true
kube-prometheus-stack:
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
  prometheusOperator:
    namespaces:
      additional:
        - my-namespace
tailing-sidecar-operator:
  scc:
    create: true
```

```bash
helm upgrade --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  -f values.yaml
```

__Notice:__ Prometheus Operator is deployed by default on OpenShift platform,
you may either limit scope for Prometheus Operator installed with Sumo Logic Kubernetes Collection using
`kube-prometheus-stack.prometheusOperator.namespaces.additional` parameter in values.yaml or
exclude namespaces for Prometheus Operator installed with Sumo Logic Kubernetes Collection
using `kube-prometheus-stack.prometheusOperator.denyNamespaces` in values.yaml.

### Additional configuration settings

#### Additional configuration for Kubernetes 1.25 or newer

`PodSecurityPolicy` is unavailable in v1.25+ so to install Helm Chart in Kubernetes 1.25 or newer you need to add following setting to your configuration:

```yaml
kube-prometheus-stack:
  global:
    rbac:
      pspEnabled: false
  kube-state-metrics:
    podSecurityPolicy:
      enabled: false
  prometheus-node-exporter:
    rbac:
      pspEnabled: false
```

#### Additional configuration for AKS 1.25

To install Helm Chart in AKS 1.25 you need to disable `PodSecurityPolicy` which is unavailable in v1.25+ and
to you use falco you need set newer version of falco image in configuration:

```yaml
kube-prometheus-stack:
  global:
    rbac:
      pspEnabled: false
  kube-state-metrics:
    podSecurityPolicy:
      enabled: false
  prometheus-node-exporter:
    rbac:
      pspEnabled: false
falco:
  image:
    registry: 'public.ecr.aws'
    repository: 'falcosecurity/falco'
    tag: '0.33.1'
```

## Viewing Data In Sumo Logic

Once you have completed installation, you can
[install the Kubernetes App and view the dashboards][sumo-k8s-app-dashboards]
or [open a new Explore tab] in Sumo Logic.
If you do not see data in Sumo Logic, you can review our
[troubleshooting guide](./Troubleshoot_Collection.md).

[sumo-k8s-app-dashboards]: https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app
[open a new Explore tab]: https://help.sumologic.com/docs/observability/kubernetes/monitoring#open-explore

## Troubleshooting Installation

### Error: timed out waiting for the condition

If `helm upgrade --install` hangs, it usually means the pre-install setup job is failing and is in a retry loop.
Due to a Helm limitation, errors from the setup job cannot be fed back to the `helm upgrade --install` command.
Kubernetes schedules the job in a pod, so you can look at logs from the pod to see why the job is failing.
First find the pod name in the namespace where the Helm chart was deployed. The pod name will contain `-setup` in the name.

```sh
kubectl get pods
```

> __Tip__: If the pod does not exist, it is possible it has been evicted.
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
The installation process creates new [HTTP endpoints](https://help.sumologic.com/docs/send-data/hosted-collectors/http-source)
in your Sumo Logic account, that are used to send data to Sumo.
This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

## Customizing Installation

All default properties for the Helm chart can be found in our [documentation](../helm/sumologic/README.md).
We recommend creating a new `values.yaml` for each Kubernetes cluster you wish
to install collection on and __setting only the properties you wish to override__.
Once you have customized you can use the following commands to install or upgrade.

```bash
helm upgrade --install my-release sumologic/sumologic -f values.yaml
```

> __Tip__: To filter or add custom metrics to Prometheus,
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

__Note:__ If you no longer have your `values.yaml` from the first installation
or do not remember the options you added via `--set` you can run the following to see the values for the currently installed helm chart.
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

> __Helm3 Tip__: In Helm3 the default behavior is to purge history.
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

### Removing the kubelet Service

The Helm chart uses the Prometheus Operator to manage Prometheus instances.
This operator creates a Service for scraping metrics exposed by the kubelet (subject to configuration in the
`kube-prometheus-stack.prometheusOperator.kubeletService` key in `values.yaml`), which isn't removed by the chart
uninstall process.
This Service is largely harmless, but can cause issues if a different release of the chart is installed, resulting in
duplicated metrics from the kubelet.
See [this issue](https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/1101) and the corresponding
[upstream issue](https://github.com/prometheus-community/helm-charts/issues/1523) for a more detailed explanation.

To remove this service after uninstalling the chart, run:

```bash
kubectl delete svc <release_name>-kube-prometheus-kubelet -n kube-system
```

Please keep in mind that if you've changed any configuration values related to this service (they reside under the
`kube-prometheus-stack.prometheusOperator.kubeletService` key in `values.yaml`), you should substitute those values in
the command provided above.
