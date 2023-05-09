# Installation

<!-- TOC -->

- [Requirements](#requirements)
  - [Helm](#helm)
    - [Non-helm installation](#non-helm-installation)
      - [OpenShift](#openshift)
  - [Sumo Logic Account](#sumo-logic-account)
  - [Sumo Logic fields](#sumo-logic-fields)
- [Add repository](#add-repository)
- [Prepare minimal configuration](#prepare-minimal-configuration)
  - [Required parameters](#required-parameters)
  - [Setting cluster name](#setting-cluster-name)
  - [Proxy](#proxy)
  - [Installing with existing Prometheus](#installing-with-existing-prometheus)
  - [Installing in Openshift platform](#installing-in-openshift-platform)
  - [Examples](#examples)
    - [Minimal configuration](#minimal-configuration)
- [Install chart](#install-chart)
- [Customizing Installation](#customizing-installation)
  - [Override names of the resources](#override-names-of-the-resources)
  - [Authenticating with container registry](#authenticating-with-container-registry)
  - [Collecting container logs](#collecting-container-logs)
  - [Collecting application metrics](#collecting-application-metrics)
  - [Collecting Kubernetes metrics](#collecting-kubernetes-metrics)
  - [Collecting Kubernetes events](#collecting-kubernetes-events)
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
- [Troubleshooting Installation](#troubleshooting-installation)
  - [General troubleshooting](#general-troubleshooting)
  - [Installation fails with error `function "dig" not defined`](#installation-fails-with-error-function-dig-not-defined)
  - [Error: timed out waiting for the condition](#error-timed-out-waiting-for-the-condition)
    - [Error: collector with name 'sumologic' does not exist](#error-collector-with-name-sumologic-does-not-exist)
    - [Secret 'sumologic::sumologic' exists, abort](#secret-sumologicsumologic-exists-abort)
  - [OpenTelemetry Collector Pods Stuck in CreateContainerConfigError](#opentelemetry-collector-pods-stuck-in-createcontainerconfigerror)
  - [Prometheus Troubleshooting](#prometheus-troubleshooting)
- [Upgrading Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)
  - [Post installation cleanup](#post-installation-cleanup)
  - [Removing the kubelet Service](#removing-the-kubelet-service)
  <!-- /TOC -->

Our Helm chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and
service level metadata; and sends them to Sumo Logic.

## Requirements

### Helm

Helm is required, but you can use it for template generation only, if you don't want to use it to manage your installation.

#### Non-helm installation

If you don't want to use Helm to manage the installation, please use `helm template` to generate Kubernetes templates and apply them using
Kubectl.

> **Warning:** > Before upgrade, please delete the old jobs:

- `kubectl delete job -n ${NAMESPACE} my-release-sumologic-setup`
- `kubectl delete job -n ${NAMESPACE} my-release-sumologic-ot-operator-instr` (needed only if `opentelemetry-operator.enabled=true`)

Simply replace:

```bash
helm upgrade \
  --install \
  -n `${NAMESPACE}` \
  --create-namespace \
  -f user-values.yaml \
  my-release \
  sumologic/sumologic
```

with

```bash
helm template \
  -n "${NAMESPACE}" \
  --create-namespace \
  -f user-values.yaml \
  my-release \
  sumologic/sumologic | tee sumologic-rendered.yaml
kubectl create namespace "${NAMESPACE}"
kubectl apply -f sumologic-rendered.yaml -n "${NAMESPACE}"
```

##### OpenShift

For Openshift, you need to add `--api-versions=security.openshift.io/v1` argument to `helm template`, so the final set of upgrade commands
will look like the following:

```
helm template \
  --api-versions=security.openshift.io/v1` \
  -n "${NAMESPACE}" \
  --create-namespace \
  -f user-values.yaml \
  my-release \
  sumologic/sumologic | tee sumologic-rendered.yaml
kubectl create namespace "${NAMESPACE}"
kubectl apply -f sumologic-rendered.yaml -n "${NAMESPACE}"
```

### Sumo Logic Account

If you don’t already have a Sumo account, you can create one by clicking the Free Trial button on https://www.sumologic.com/.

The following are required to set up Sumo Logic's Kubernetes collection.

- An [Access ID and Access Key](https://help.sumologic.com/docs/manage/security/access-keys/) with
  [Manage Collectors](https://help.sumologic.com/docs/manage/users-roles/roles/role-capabilities#data-management) capability.
- Please review our [minimum requirements](/docs/README.md#minimum-requirements) and [support matrix](/docs/README.md#support-matrix)

To get an idea of the resources this chart will require to run on your cluster, you can reference our [performance doc](performance.md).

### Sumo Logic fields

Sumo Logic Apps for Kubernetes and Explore require below listed fields to be added in Sumo Logic UI to your Fields table schema.

- `cluster`
- `container`
- `daemonset`
- `deployment`
- `host`
- `namespace`
- `node`
- `pod`
- `service`
- `statefulset`

This is normally done in the setup job when `sumologic.setupEnabled` is set to `true` (default behavior).

In an unlikely scenario that this fails please create them manually by visiting
[Fields#Manage_fields](https://help.sumologic.com/docs/manage/fields/#manage-fields) in Sumo Logic UI.

This is to ensure your logs are tagged with relevant metadata.

This is a one time setup per Sumo Logic account.

## Add repository

Before installing the chart, you need to add the `sumologic` Helm repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
helm repo update
```

## Prepare minimal configuration

Next you can prepare a `user-values.yaml` file with your configuration.

### Required parameters

The Helm chart installation requires two parameter overrides:

- `sumologic.accessId` - Sumo [Access ID](https://help.sumologic.com/docs/manage/security/access-keys/).
- `sumologic.accessKey` - Sumo [Access key](https://help.sumologic.com/docs/manage/security/access-keys/).

### Setting cluster name

The following parameter is optional, but we recommend setting it.

- `sumologic.clusterName` - An identifier for your Kubernetes cluster. This is the name you will see for the cluster in Sumo Logic. Default
  is `kubernetes`. Whitespaces in the cluster name will be replaced with dashes.

### Proxy

If you are installing the collection in a cluster that requires proxying outbound requests, please see the following
[additional properties](installing-behind-proxy.md) you will need to set.

### Installing with existing Prometheus

If you already have Prometheus installed in your cluster, and would like to use it instead of the Prometheus instance provided by the Chart,
please see [Prometheus document](/docs/prometheus.md#prometheus)

### Installing in OpenShift platform

The daemonset/statefulset fails to create the pods in Openshift environment due to the request of elevated privileges, like HostPath mounts,
privileged: true, etc.

If you wish to install the chart in the Openshift Platform, it requires a SCC resource which is only created in Openshift (detected via API
capabilities in the chart), you can add the following configuration to `user-values.yaml`:

```yaml
sumologic:
  scc:
    create: true
otellogs:
  daemonset:
    containers:
      otelcol:
        securityContext:
          privileged: true
    initContainers:
      changeowner:
        securityContext:
          privileged: true
tailing-sidecar-operator:
  scc:
    create: true
```

**Notice:** Prometheus Operator is deployed by default on OpenShift platform, you may either limit scope for Prometheus Operator installed
with Sumo Logic Kubernetes Collection using `kube-prometheus-stack.prometheusOperator.namespaces.additional` parameter in `user-values.yaml`
or exclude namespaces for Prometheus Operator installed with Sumo Logic Kubernetes Collection using
`kube-prometheus-stack.prometheusOperator.denyNamespaces` in `user-values.yaml`. For details see
[Prometheus document](/docs/prometheus.md#prometheus-operator-in-the-cluster)

### Examples

#### Minimal configuration

An example file with the minimum configuration is provided below.

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
```

More configuration examples (i.e. OpenShift) can be seen in [this document](/docs/configuration-examples.md).

## Install chart

Now you can install our chart. The following command will install the Sumo Logic chart with the release name `my-release` in the
`${NAMESPACE}` namespace.

```bash
helm upgrade \
  --install \
  -n `${NAMESPACE}` \
  --create-namespace \
  -f user-values.yaml \
  my-release \
  sumologic/sumologic
```

> **Note**: If the release exists, it will be upgraded, otherwise it will be installed.
>
> **Note**: If the namespace doesn't exists, it will be created.

## Customizing Installation

All default properties for the Helm chart can be found in our [documentation](/deploy/helm/sumologic/README.md). We recommend creating a new
`user-values.yaml` for each Kubernetes cluster you wish to install collection on and **setting only the properties you wish to override**.
Once you have customized you should use the following commands to install or upgrade.

```bash
helm upgrade \
  --install \
  -n `${NAMESPACE}` \
  --create-namespace \
  -f user-values.yaml \
  my-release \
  sumologic/sumologic
```

We documented some common customizations:

- [Override names of the resources](#override-names-of-the-resources)
- [Authenticating with container registry](#authenticating-with-container-registry)
- [Collecting container logs](#collecting-container-logs)
- [Collecting application metrics](#collecting-application-metrics)
- [Collecting Kubernetes metrics](#collecting-kubernetes-metrics)
- [Collecting Kubernetes events](#collecting-kubernetes-events)

### Override names of the resources

If you want to override the names of the resources created by the chart, see
[Overriding chart resource names with `fullnameOverride`](best-practices.md#overriding-chart-resource-names-with-fullnameoverride).

### Authenticating with container registry

Sumo Logic container images used for collection are currently hosted on [Amazon Public ECR][aws-public-ecr-docs] which requires
authentication to provide a higher quota for image pulls. To find a comprehensive information on this please refer to [Amazon Elastic
Container Registry pricing][aws-ecr-pricing].

Please refer to [our instructions](/docs/working-with-container-registries.md#authenticating-with-container-registry) on how to provide
credentials in order to authenticate with Docker Hub.

An alternative would be to host Sumo Logic container images in one's container registries. To do so please refer to the following
[instructions](/docs/working-with-container-registries.md#hosting-sumo-logic-images)

[aws-public-ecr-docs]: https://aws.amazon.com/blogs/aws/amazon-ecr-public-a-new-public-container-registry/
[aws-ecr-pricing]: https://aws.amazon.com/ecr/pricing/

### Collecting container logs

Refer to [Collecting Container Logs document](/docs/collecting-container-logs.md#collecting-container-logs)

### Collecting application metrics

Refer to [Collecting Application Metrics document](/docs/collecting-application-metrics.md#collecting-application-metrics)

### Collecting Kubernetes metrics

Refer to [Collecting Kubernetes Metrics document](/docs/collecting-kubernetes-metrics.md#collecting-kubernetes-metrics)

### Collecting Kubernetes events

Refer to [Collecting Kubernetes Events document](/docs/collecting-kubernetes-events.md#collecting-kubernetes-events)

## Viewing Data In Sumo Logic

Once you have completed installation, you can [install the Kubernetes App and view the dashboards][sumo-k8s-app-dashboards] or [open a new
Explore tab] in Sumo Logic. If you do not see data in Sumo Logic, you can review our [troubleshooting guide](troubleshoot-collection.md).

[sumo-k8s-app-dashboards]: https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app
[open a new explore tab]: https://help.sumologic.com/docs/observability/kubernetes/monitoring#open-explore

## Troubleshooting Installation

### General troubleshooting

Please refer to [Troubleshooting document](/docs/troubleshoot-collection.md#troubleshooting-collection).

### Installation fails with error `function "dig" not defined`

You need to use a more recent version of Helm. See [Minimum Requirements](/docs/README.md#minimum-requirements).

If you are using ArgoCD or another tool that uses Helm under the hood, make sure that tool uses the required version of Helm.

### Error: timed out waiting for the condition

If `helm upgrade --install` hangs, it usually means the pre-install setup job is failing and is in a retry loop. Due to a Helm limitation,
errors from the setup job cannot be fed back to the `helm upgrade --install` command. Kubernetes schedules the job in a pod, so you can look
at logs from the pod to see why the job is failing. First find the pod name in the namespace where the Helm chart was deployed. The pod name
will contain `-setup` in the name.

```sh
kubectl get pods
```

> **Tip**: If the pod does not exist, it is possible it has been evicted. Re-run the `helm upgrade --install` to recreate it and while that
> command is running, use another shell to get the name of the pod.

Get the logs from that pod:

```
kubectl logs POD_NAME -f
```

#### Error: collector with name 'sumologic' does not exist

If you get

```
Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID
```

you can safely ignore it and the installation should complete successfully. The installation process creates new
[HTTP endpoints](https://help.sumologic.com/docs/send-data/hosted-collectors/http-source) in your Sumo Logic account, that are used to send
data to Sumo. This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](troubleshoot-collection.md).

#### Secret 'sumologic::sumologic' exists, abort

If you see `Secret 'sumologic::sumologic' exists, abort.` from the logs, delete the existing secret:

```bash
kubectl delete secret sumologic -n ${NAMESPACE}
```

`helm install` should proceed after the existing secret is deleted before exhausting retries. If it did time out after exhausting retries,
rerun the `helm install` command.

### OpenTelemetry Collector Pods Stuck in CreateContainerConfigError

If the OpenTelemetry Collector Pods are in `CreateContainerConfigError` it can mean the setup job has not been completed yet. Make sure that
the `sumologic.setupEnable` parameter is set to `true`. Then wait for the setup pod to complete and the issue should resolve itself. The
setup job creates a secret and the error simply means the secret is not there yet. This usually resolves itself automatically.

If the issue does not solve resolve automatically, you will need to look at the logs for the setup pod. Kubernetes schedules the job in a
pod, so you can look at logs from the pod to see why the job is failing. First find the pod name in the namespace where you installed the
rendered YAML. The pod name will contain `-setup` in the name.

```sh
kubectl get pods
```

Get the logs from that pod:

```
kubectl logs POD_NAME -f
```

### Prometheus Troubleshooting

Please refer to [Troubleshooting section in Prometheus document](/docs/prometheus.md#troubleshooting).

## Upgrading Sumo Logic Collection

To upgrade our helm chart to a newer version, you must first run update your local helm repo.

```bash
helm repo update
```

Next, you can run `helm upgrade --install` to upgrade to that version. The following upgrades the current version of `my-release` to the
latest.

```bash
helm upgrade --install my-release sumologic/sumologic -f `user-values.yaml`
```

If you wish to upgrade to a specific version, you can use the `--version` flag.

```bash
helm upgrade --install my-release sumologic/sumologic -f `user-values.yaml` --version=2.0.0
```

**Note:** If you no longer have your `user-values.yaml` from the first installation or do not remember the options you added via `--set` you
can run the following to see the values for the currently installed helm chart. For example, if the release is called `my-release` you can
run the following.

```bash
helm get values my-release
```

If something goes wrong, or you want to go back to the previous version, you can
[rollback changes using helm](https://helm.sh/docs/helm/helm_rollback/):

```
helm history my-release
helm rollback my-release <REVISION-NUMBER>
```

## Uninstalling Sumo Logic Collection

To uninstall/delete the Helm chart:

```bash
helm delete my-release
```

> **Helm3 Tip**: In Helm3 the default behavior is to purge history. Use --keep-history to preserve it while deleting the release.

The command removes all the Kubernetes components associated with the chart and deletes the release.

### Post installation cleanup

In order to clean up the Kubernetes secret and associated hosted collector one can use the optional cleanup job by setting
`sumologic.cleanupEnabled` to `true`.

Alternatively the secret can be removed manually with:

```bash
kubectl delete secret sumologic
```

and the associated hosted collector can be deleted in the Sumo Logic UI.

### Removing the kubelet Service

The Helm chart uses the Prometheus Operator to manage Prometheus instances. This operator creates a Service for scraping metrics exposed by
the kubelet (subject to configuration in the `kube-prometheus-stack.prometheusOperator.kubeletService` key in `user-values.yaml`), which
isn't removed by the chart uninstall process. This Service is largely harmless, but can cause issues if a different release of the chart is
installed, resulting in duplicated metrics from the kubelet. See
[this issue](https://github.com/SumoLogic/sumologic-kubernetes-collection/issues/1101) and the corresponding
[upstream issue](https://github.com/prometheus-community/helm-charts/issues/1523) for a more detailed explanation.

To remove this service after uninstalling the chart, run:

```bash
kubectl delete svc <release_name>-kube-prometheus-kubelet -n kube-system
```

Please keep in mind that if you've changed any configuration values related to this service (they reside under the
`kube-prometheus-stack.prometheusOperator.kubeletService` key in `user-values.yaml`), you should substitute those values in the command
provided above.
