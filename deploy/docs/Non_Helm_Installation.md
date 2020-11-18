# Non Helm Installation

**Please note that our non-helm installation process still uses Helm to generate
the YAML that you will deploy into your Kubernetes cluster.
We do not provide YAML that can be directly applied and it must be generated.**

This document has instructions for setting up Sumo Logic collection using Fluentd,
Fluent-Bit, Prometheus and Falco.

<!-- TOC -->
* [Requirements](#requirements)
* [Prerequisite](#prerequisite)
* [Installation Steps](#installation-steps)
  * [Authenticating with container registry](#authenticating-with-container-registry)
  * [Installation in Openshift Platform](#installation-in-openshift-platform)
* [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic)
* [Troubleshooting Installation](#troubleshooting-installation)
  * [Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists](#error-customresourcedefinitionsapiextensionsk8sio-alertmanagersmonitoringcoreoscom-already-exists)
  * [Fluentd Pods Stuck in CreateContainerConfigError](#fluentd-pods-stuck-in-createcontainerconfigerror)
  * [Error: collector with name 'sumologic' does not exist](#error-collector-with-name-sumologic-does-not-exist)
* [Customizing Installation](#customizing-installation)
* [Upgrading Sumo Logic Collection](#upgrading-sumo-logic-collection)
* [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection)
<!-- /TOC -->

## Requirements

If you don’t already have a Sumo account, you can create one by clicking
the Free Trial button on https://www.sumologic.com/.

The following are required to setup Sumo Logic's Kubernetes collection.

* An [Access ID and Access Key](https://help.sumologic.com/Manage/Security/Access-Keys)
  with [Manage Collectors] capability.
* Please review our [minimum requirements](../README.md#minimum-requirements)
  and [support matrix](../README.md#support-matrix)

[Manage Collectors]: https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities#data-management

To get an idea of the resources this chart will require to run on your cluster,
you can reference our [performance doc](./Performance.md).

## Prerequisite

Sumo Logic Apps for Kubernetes and Explore require you to add the following
[fields](https://help.sumologic.com/Manage/Fields#Manage_fields) in the Sumo Logic UI
to your Fields table schema.
This is to ensure your logs are tagged with relevant metadata.
This is a one time setup per Sumo Logic account.

* cluster
* container
* deployment
* host
* namespace
* node
* pod
* service

## Installation Steps

These steps require that no Prometheus exists.
If you already have Prometheus installed select from the following options:

* [How to install our Chart side by side with your existing Prometheus Operator](./SideBySidePrometheus.md)
* [How to install if you have an existing Prometheus Operator you want to update](./existingPrometheusDoc.md)
* [How to install if you have standalone Prometheus (not using Prometheus Operator)](./standAlonePrometheus.md)

In this method of installation, you will use our [templating tool](https://github.com/SumoLogic/sumologic-kubernetes-tools#k8s-template-generator) to generate the YAML needed to deploy Sumo Logic collection for Kubernetes.  This tool will use our Helm chart to generate the YAML.  You will configure the collection the same way that you would for Helm based install.  However, instead of using Helm to install the Chart, the tool will output the rendered YAML you can deploy.

The installation requires two parameters:

* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

If you are installing the collection in a cluster that requires proxying outbound requests,
please see the following [additional properties](./Installing_Behind_Proxy.md) you will need to set.

The following parameter is optional, but we recommend setting it.

* __sumologic.clusterName__ - An identifier for your Kubernetes cluster.
  This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

First you will generate the YAML to apply to your cluster.  The following command contains the minimum parameters that can generate the YAML to setup Sumo Logic's Kubernetes collection. This command will generate the YAML and pipe it a file called `sumologic.yaml`. Please note that `--namespace` is required

```bash
kubectl run tools \
  -it --quiet --rm \
  --restart=Never \
  --image sumologic/kubernetes-tools:2.0.0 -- \
  template \
  --name-template 'collection' \
  --set sumologic.accessId='<ACCESS_ID>' \
  --set sumologic.accessKey='<ACCESS_KEY>' \
  --set sumologic.clusterName='<CLUSTER_NAME>' \
  | tee sumologic.yaml
```

Next, you will need to apply the required CRD's for the Prometheus Operator.
This is required before applying the generated YAML.

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
```

If you are on Kubernetes 1.14 or earlier, you may received the following error:

```
ValidationError(CustomResourceDefinition.spec): unknown field "preserveUnknownFields" in io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1beta1.CustomResourceDefinitionSpec; if you choose to ignore these errors, turn validation off with --validate=false
```

Simply add the `--validate=false` flag to the `kubectl apply` commands.

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml --validate=false
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml --validate=false
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml --validate=false
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml --validate=false
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml --validate=false
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml --validate=false
```

Finally, you can run `kubectl apply` on the file containing the rendered YAML
from the previous step.

```bash
kubectl apply -f sumologic.yaml
```

If you wish to install the YAML in a different namespace, you can add the `--namespace` flag.
The following will render the YAML and install in the `my-namespace` namespace.

```bash
kubectl run tools \
  -it --quiet --rm \
  --restart=Never \
  --image sumologic/kubernetes-tools:2.0.0 -- \
  template \
  --namespace 'my-namespace' \
  --name-template 'collection' \
  --set sumologic.accessId='<ACCESS_ID>' \
  --set sumologic.accessKey='<ACCESS_KEY>' \
  --set sumologic.clusterName='<CLUSTER_NAME>' \
  | tee sumologic.yaml
```

Finally, you can run `kubectl apply` on the file containing the rendered YAML
from the previous step.
You must change your `kubectl` context to the namespace you wish to install in.

```bash
kubectl config set-context --current --namespace=my-namespace
kubectl apply -f sumologic.yaml
```

### Authenticating with container registry

Sumo Logic container images used in the collection are currently hosted on hub.docker.com which
[requires authentication in order to provide higher quota for image pulls][docker-rate-limit].

Please refer to [our instructions](/deploy/docs/Authenticating_with_docker_registry.md)
on how to provide credentials in order to authenticate with the registry.

[docker-rate-limit]: https://www.docker.com/increase-rate-limits

### Installation in Openshift Platform

The daemonset/statefulset fails to create the pods in Openshift environment
due to the request of elevated privileges, like HostPath mounts, privileged: true, etc.

If you wish to install the chart in the Openshift Platform, it requires a SCC resource
which is only created in Openshift (detected via API capabilities in the chart),
you can do the following:

```bash
kubectl run tools \
  -it --quiet --rm \
  --restart=Never \
  --image sumologic/kubernetes-tools:2.0.0 -- \
  template \
  --namespace 'my-namespace' \
  --name-template 'collection' \
  --set sumologic.accessId='<ACCESS_ID>' \
  --set sumologic.accessKey='<ACCESS_KEY>' \
  --set sumologic.clusterName='<CLUSTER_NAME>' \
  --set sumologic.scc.create=true \
  --set fluent-bit.securityContext.privileged=true \
  | tee sumologic.yaml
```

## Viewing Data In Sumo Logic

Once you have completed installation, you can
[install the Kubernetes App and view the dashboards][install-k8s-app] or
[open a new Explore tab] in Sumo Logic.
If you do not see data in Sumo Logic, you can review our [troubleshooting guide](./Troubleshoot_Collection.md).

[install-k8s-app]: https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards
[open a new Explore tab]: https://help.sumologic.com/Solutions/Kubernetes_Solution/05Navigate_your_Kubernetes_environment

## Troubleshooting Installation

### Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists

If you get `Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists` it means you did not apply the CRD's yet.  Please make sure you apply CRD's before rendering as documented above.

### Fluentd Pods Stuck in CreateContainerConfigError

If the fluentd pods are in `CreateContainerConfigError` it can mean the setup job has not completed yet. Wait for the setup pod to complete and the issue should resolve itself.  The setup job creates a secret and the error simply means the secret is not there yet.  This usually resolves itself automatically.

If the issue does not solve resolve automatically, you will need to look at the logs for the setup pod. Kubernetes schedules the job in a pod, so you can look at logs from the pod to see why the job is failing. First find the pod name in the namespace where you installed the rendered YAML. The pod name will contain `-setup` in the name.

```sh
kubectl get pods
```

Get the logs from that pod:

```
kubectl logs POD_NAME -f
```

### Error: collector with name 'sumologic' does not exist

If you get `Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID`, you can safely
ignore it and the installation should complete successfully.
The installation process creates new [HTTP endpoints] in your Sumo Logic account,
that are used to send data to Sumo.
This error occurs if the endpoints had already been created by an earlier run
of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

[HTTP endpoints]: https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source

## Customizing Installation

All default properties for the Helm chart can be found in our
[documentation](../helm/sumologic/README.md).
We recommend creating a new `values.yaml` for each Kubernetes cluster you wish
to install collection on and **setting only the properties you wish to override**.
Once you have customized the file you can generate the YAML.
The content of the `values.yaml` can be fed into the template generator as shown below.

```bash
cat sumo-values.yaml | \
  kubectl run tools \
    -i --quiet --rm \
    --restart=Never \
    --image sumologic/kubernetes-tools:2.0.0 -- \
    template \
      --name-template 'collection' \
      | tee sumologic.yaml
```

> **Tip**: To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Upgrading Sumo Logic Collection

**Note, if you are upgrading to version 1.x of our collection from a version before 1.x,
please see our [migration guide](v1_migration_doc.md).**

To upgrade you can simply re-generate the YAML when a new version
of the Kubernetes collection is available.
You can use the same commands used to create the YAML in the first place.

```bash
kubectl run tools \
  -it --quiet --rm \
  --restart=Never \
  --image sumologic/kubernetes-tools:2.0.0 -- \
  template \
  --namespace 'my-namespace' \
  --name-template 'collection' \
  --set sumologic.accessId='<ACCESS_ID>' \
  --set sumologic.accessKey='<ACCESS_KEY>' \
  --set sumologic.clusterName='<CLUSTER_NAME>' \
  | tee sumologic.yaml
```

If you have made customizations and installed with a `values.yaml`, you can do
the same thing command as you did before to generate the YAML.

```bash
cat sumo-values.yaml | \
     kubectl run tools \
       -i --quiet --rm \
       --restart=Never \
       --image sumologic/kubernetes-tools:2.0.0 -- \
       template \
         --name-template 'collection' \
         | tee sumologic.yaml
```

If you wish to upgrade to a specific version, you can pass the `--version` flag
when generating the YAML.
The following example would use version `1.0.0`.

```bash
cat values.yaml | \
  kubectl run tools \
    -i --quiet --rm \
    --restart=Never \
    --image sumologic/kubernetes-tools:2.0.0 -- \
    template \
      --name-template 'collection' \
      --version=1.0.0
      | tee sumologic.yaml
```

Once you have generated the `sumologic.yaml`, you can run `kubectl apply` on
the file containing the rendered YAML from the previous step to upgrade collection.
You must change your `kubectl` context to the namespace you wish to install in.

```bash
kubectl config set-context --current --namespace=my-namespace
kubectl apply -f sumologic.yaml
```

## Uninstalling Sumo Logic Collection

To uninstall/delete, simply run `kubectl delete` on the generated YAML.

```bash
kubectl delete -f sumologic.yaml
```

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.
