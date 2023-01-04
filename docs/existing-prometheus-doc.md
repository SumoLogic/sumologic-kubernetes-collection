# How to install if you have an existing Prometheus operator

__NOTE__: The Sumo Logic Kubernetes collection process does not support collecting
metrics from scaling Prometheus replicas.
If you are running multiple Prometheus replicas, please follow our
[Side-by-Side](side-by-side-prometheus.md) instructions.

- [Requirements](#requirements)
- [Prerequisite](#prerequisite)
- [Install Sumo Logic Helm Chart](#install-sumo-logic-helm-chart)
- [Update Existing Kube Prometheus Stack Helm Chart](#update-existing-kube-prometheus-stack-helm-chart)
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
- [Merge Prometheus Configuration](#merge-prometheus-configuration)
- [Troubleshooting](#troubleshooting)
  - [UPGRADE FAILED: failed to create resource: Internal error occurred: failed calling webhook "prometheusrulemutate.monitoring.coreos.com"](#upgrade-failed-failed-to-create-resource-internal-error-occurred-failed-calling-webhook-prometheusrulemutatemonitoringcoreoscom)
  - [Error: timed out waiting for the condition](#error-timed-out-waiting-for-the-condition)
  - [Error: collector with name 'sumologic' does not exist](#error-collector-with-name-sumologic-does-not-exist)
- [Customizing Installation](#customizing-installation)
- [Upgrading Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)

This document will walk you through how to set up Sumo Logic Kubernetes collection
when you already have Prometheus running using the Prometheus Operator.
In these steps, you will modify your installed Prometheus operator to add in
the minimum configuration that Sumo Logic needs.

If you do not wish to modify your Prometheus Operator and wish to run it side-by-side
with our collection, please refer to our
[How to install our Prometheus side by side with your existing Prometheus](side-by-side-prometheus.md) documentation.

## Requirements

If you don’t already have a Sumo account, you can create one by clicking the Free Trial button on https://www.sumologic.com/.

The following are required to setup Sumo Logic's Kubernetes collection.

- An [Access ID and Access Key](https://help.sumologic.com/docs/manage/security/access-keys/) with [Manage Collectors](https://help.sumologic.com/docs/manage/users-roles/roles/role-capabilities#data-management) capability.
- Please review our [minimum requirements](/docs/README.md#minimum-requirements) and [support matrix](/docs/README.md#support-matrix)

To get an idea of the resources this chart will require to run on your cluster, you can reference our [performance doc](performance.md).

## Prerequisite

Sumo Logic Apps for Kubernetes and Explore require you to add the following
[fields](https://help.sumologic.com/docs/manage/fields/#manage-fields) in theSumo Logic UI
to your Fields table schema.
This is to ensure your logs are tagged with relevant metadata.
This is a one time setup per Sumo Logic account.

- cluster
- container
- deployment
- host
- namespace
- node
- pod
- service

## Install Sumo Logic Helm Chart

The Helm chart installation requires two parameter overrides:

- __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/docs/manage/security/access-keys/).
- __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/docs/manage/security/access-keys/).

To get an idea of the resources this chart will require to run on your cluster,
you can reference our [performance doc](performance.md).

If you are installing the collection in a cluster that requires proxying outbound requests,
please see the following [additional properties](installing-behind-proxy.md) you will need to set.

The following parameter is optional, but we recommend setting it.

- __sumologic.clusterName__ - An identifier for your Kubernetes cluster.
  This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.
  Whitespaces in the cluster name will be replaced with dashes.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can prepare `user-values.yaml` with configuration.
An example file with the minimum confiuration is provided below.
It disables the `kube-prometheus-stack` sub-chart since
we will be modifying the existing prometheus operator install.

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
kube-prometheus-stack:
  enabled: false
```

Now you can run `helm upgrade --install` to install our chart.
The following command will install the Sumo Logic chart with the release name `my-release`
in the namespace your `kubectl` context is currently set to.

```bash
helm upgrade --install my-release sumologic/sumologic \
  -f user-values.yaml
```

> __Note__: If the release exists, it will be upgraded, otherwise it will be installed.

If the namespace does not exist, you can add the `--create-namespace` flag.

```bash
helm upgrade \
  --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  -f user-values.yaml \
  --create-namespace
```

If you are installing the helm chart in Openshift platform, ensure that operator is listening for `my-namespace`
by adding the following configuration to `user-values.yaml`:

```yaml
sumologic:
  scc:
    create: true
tailing-sidecar-operator:
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
```

so, it should looks like the following way:

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
  scc:
    create: true
tailing-sidecar-operator:
  scc:
    create: true
kube-prometheus-stack:
  enabled: false
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
```

and then upgrade it to apply configuration:

```bash
helm upgrade \
  --install my-release sumologic/sumologic \
  --namespace=my-namespace \
  -f user-values.yaml
```

## Update Existing Kube Prometheus Stack Helm Chart

__Note that if you have made extensive customization to the current Prometheus Operator Helm
install then you will need to [merge your existing configuration with ours](#merge-prometheus-configuration)
avoiding conflicts or you may want to [run our Prometheus side-by-side](side-by-side-prometheus.md).__

Next you will modify your Prometheus Operator installation with the required configuration
to collect the metrics into Sumo Logic.
Please note that this process is best when you have not customized the existing Prometheus Operator installation.
If you have, please look at [our section on merging the configuration](#merge-prometheus-configuration).

If the Prometheus Operator is installed in a different namespace as compared to where
the Sumo Logic Chart is deployed, you would need to do the following step to copy
the `ConfigMap` that exposes the release name, which is used in the remote write urls.

For example:\
If the Sumo Logic Solution is deployed in `<source-namespace>` and the existing
kube-prometheus-stack is in `<destination-namespace>`, run the below command:

```bash
kubectl get configmap sumologic-configmap \
--namespace=<source-namespace> -o yaml | \
kubectl apply --namespace=<destination-namespace> -f -
```

Run the following commands to update the
[remote write configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)
of the prometheus operator with the prometheus overrides based on our `values.yaml`.

First, generate the Prometheus Operator `prometheus-overrides.yaml` by running commands below:

```bash
 # using kubectl
 kubectl run tools \
  -it --quiet --rm \
  --restart=Never -n sumologic \
  --image sumologic/kubernetes-tools:2.9.0 \
  -- template-dependency kube-prometheus-stack > prometheus-overrides.yaml

 # or using docker
 docker run -it --rm \
  sumologic/kubernetes-tools:2.9.0 \
  template-dependency kube-prometheus-stack > prometheus-overrides.yaml
```

Please review our configuration as it will be applied to your existing operator configuration.

Next you can upgrade your Prometheus-Operator.
The following command assumes it is installed with the release name `kube-prometheus-stack`.
Remember, this command will update your Prometheus Operator to be configured with our default settings.
If you wish to preserve your settings and merge with what is required for Sumo logic,
then please look at the section on [how to merge the configuration](#merge-prometheus-configuration).

```bash
helm upgrade kube-prometheus-stack stable/kube-prometheus-stack -f prometheus-overrides.yaml
```

## Viewing Data In Sumo Logic

Once you have completed installation, you can
[install the Kubernetes App and view the dashboards][sumo-k8s-app-dashboards] or
or [open a new Explore tab] in Sumo Logic.
If you do not see data in Sumo Logic, you can review our [troubleshooting guide](troubleshoot-collection.md).

[sumo-k8s-app-dashboards]: https://help.sumologic.com/docs/integrations/containers-orchestration/kubernetes#installing-the-kubernetes-app
[open a new Explore tab]: https://help.sumologic.com/docs/observability/kubernetes/monitoring#open-explore

## Merge Prometheus Configuration

__Note__: Make sure your `Prometheus Operator` and/or `Prometheus Operator Chart` are compatible with the version used by the Collection

If you have customized your Prometheus configuration, follow these steps to merge the configurations.

Helm supports providing multiple configuration files, and priority will be given to the last (right-most) file specified.
You can obtain your current prometheus configuration by running

```bash
helm get values $PROMETHEUS_OPERATOR_CHART_NAME > current-user-values.yaml
```

Any section of `current-user-values.yaml` that conflicts with sections of our
`prometheus-overrides.yaml` will have to be removed from the `prometheus-overrides.yaml` file
and appended to `current-user-values.yaml` in relevant sections.
For any config that doesn’t conflict, you can leave them in `prometheus-overrides.yaml`.
Then run

```bash
helm upgrade $PROMETHEUS_OPERATOR_CHART_NAME stable/kube-prometheus-stack -f current-user-values.yaml -f prometheus-overrides.yaml
```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](collecting-application-metrics.md)

## Troubleshooting

### UPGRADE FAILED: failed to create resource: Internal error occurred: failed calling webhook "prometheusrulemutate.monitoring.coreos.com"

If you receive the above error, you can take the following steps and then repeat the `helm upgrade` command.

```bash
kubectl delete  validatingwebhookconfigurations.admissionregistration.k8s.io kube-prometheus-stack-admission
kubectl delete  MutatingWebhookConfiguration  kube-prometheus-stack-admission
```

### Error: timed out waiting for the condition

If `helm upgrade --install` hangs, it usually means the pre-install setup job
is failing and is in a retry loop.
Due to a Helm limitation, errors from the setup job cannot be fed back to
the `helm upgrade --install` command.
Kubernetes schedules the job in a pod, so you can look at logs from the pod to see why the job is failing.
First find the pod name in the namespace where the Helm chart was deployed.
The pod name will contain `-setup` in the name.

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

If you get `Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID`, you can safely ignore
it and the installation should complete successfully.
The installation process creates new [HTTP endpoints](https://help.sumologic.com/docs/send-data/hosted-collectors/http-source)
in your Sumo Logic account, that are used to send data to Sumo.
This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](troubleshoot-collection.md).

## Customizing Installation

All default properties for the Helm chart can be found in our [documentation](/deploy/helm/sumologic/README.md).
We recommend creating a new `user-values.yaml` for each Kubernetes cluster you wish
to install collection on and __setting only the properties you wish to override__.
Once you have customized you can use the following commands to install or upgrade.
Remember to define the properties in our [requirements section](#requirements)
in the `user-values.yaml` as well

```bash
helm upgrade --install my-release sumologic/sumologic -f user-values.yaml
```

> __Tip__: To filter or add custom metrics to Prometheus,
> [please refer to this document](collecting-application-metrics.md)

## Upgrading Sumo Logic Collection

To upgrade our helm chart to a newer version, you must first run update your local helm repo.

```bash
helm repo update
```

Next, you can run `helm upgrade --install` to upgrade to that version. The following upgrades the current version of `my-release` to the latest.

```bash
helm upgrade --install my-release sumologic/sumologic -f user-values.yaml
```

If you wish to upgrade to a specific version, you can use the `--version` flag.

```bash
helm upgrade --install my-release sumologic/sumologic -f user-values.yaml --version=1.0.0
```

__Note:__ If you no longer have your `user-values.yaml` from the first installation
or do not remember the options you added via `--set` you can run the following to see the values for the currently installed helm chart.
For example, if the release is called `my-release` you can run the following.

```bash
helm get values my-release
```

After upgrading the Sumo Logic chart, you can repeat the steps described in [Update Existing Prometheus Operator Helm Chart](#update-existing-kube-prometheus-stack-helm-chart) to upgrade the Prometheus configuration.

## Uninstalling Sumo Logic Collection

To uninstall/delete the Helm chart:

```bash
helm delete my-release
```

> __Helm3 Tip__: In Helm3 the default behavior is to purge history.
> Use `--keep-history` to preserve it while deleting the release.

The command removes all the Kubernetes components associated with the chart and deletes the release.

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.

Finally, you can restore your Prometheus to the original configuration before you installed Sumo Logic.
