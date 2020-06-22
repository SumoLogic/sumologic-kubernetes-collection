# Non Helm Installation

**Please note that our non-helm installation process still uses Helm to generate the YAML that you will deploy into your Kubernetes cluster.  We do not provide YAML that can be directly be applied and it must be generated.**

This document has instructions for setting up Sumo Logic collection using Fluentd, FluentBit, Prometheus and Falco. 

<!-- TOC -->

- [Requirements](#requirements) 
- [Prerequisite](#prerequisite)
- [Installation Steps](#installation-steps) 
- [Viewing Data In Sumo Logic](#viewing-data-in-sumo-logic) 
- [Troubleshooting Installation](#troubleshooting-installation)
- [Customizing Installation](#customizing-installation)
- [Upgrade Sumo Logic Collection](#upgrading-sumo-logic-collection)
- [Uninstalling Sumo Logic Collection](#uninstalling-sumo-logic-collection) 

<!-- /TOC -->

## Requirements

If you don’t already have a Sumo account, you can create one by clicking the Free Trial button on https://www.sumologic.com/.

The following are required to setup Sumo Logic's Kubernetes collection.

  * An [Access ID and Access Key](https://help.sumologic.com/Manage/Security/Access-Keys) with [Manage Collectors](https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities#data-management) capability.
  * Your Kubernetes cluster must allow [outbound access to Sumo Logic](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security) to setup collection. Using a proxy is not currently supported.
  * Please review our [minimum requirements](../README.md#minimum-requirements) and [support matrix](../README.md#support-matrix)

## Prerequisite

Sumo Logic Apps for Kubernetes and Explore require you to add the following [fields](https://help.sumologic.com/Manage/Fields) in the Sumo Logic UI to your Fields table schema. This is to ensure your logs are tagged with relevant metadata. This is a one time setup per Sumo Logic account.
- cluster
- container
- deployment
- host
- namespace
- node
- pod
- service

## Installation Steps

These steps require that no Prometheus exists. If you already have Prometheus installed select from the following options:

- [How to install if you have an existing Prometheus operator](./existingPrometheusDoc.md) 
- [How to install if you have standalone Prometheus](./standAlonePrometheus.md) 
- [How to install our Prometheus side by side with your existing Prometheus](./SideBySidePrometheus.md)

In this method of installation, you will use our [templating tool](https://github.com/SumoLogic/sumologic-kubernetes-tools#k8s-template-generator) to generate the YAML needed to deploy Sumo Logic collection for Kubernetes.  This tool will use our Helm chart to generate the YAML.  You will configure the collection the same way that you would for Helm based install.  However, inseat of using Helm to install the Chartm, the tool will output the rendered YAML you can deploy.

The installation requires two parameters:
* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

The following parameter is optional, but we recommend setting it.
* __sumologic.clusterName__ - An identifier for your Kubernetes cluster.  This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

First, you will need to apply the required CRD's for the Prometheus Operator. This is required before generating the YAML.

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
```

Next you will generate the YAML to apply to your cluster.  The following command contains the minimum parameters that can generate the YAML to setup Sumo Logic's Kubernetes collection. This command will generate the YAML and pipe it a file called `sumologic.yaml`.

```bash
kubectl run tools \
  -it --quiet --rm \
  --restart=Never \
  --image sumologic/kubernetes-tools -- \
  template \
  --name-template 'collection' \
  --set sumologic.accessId='<ACCESS_KEY>' \
  --set sumologic.accessKey='<ACCESS_ID>' \
  --set sumologic.clusterName='<CLUSTER_NAME>' \
  | tee sumologic.yaml
```

Finally, you can run `kubectl apply` on the file containing the rendered YAML from the previous step.

```bash
kubectl apply -f sumologic.yaml
```

If you with to install the YAML in a different namespace, you can add the `--namespace` flag.  The following will render the YAML and install in the `my-namespace` namespace.

```bash
kubectl run tools \
  -it --quiet --rm \
  --restart=Never \
  --image sumologic/kubernetes-tools -- \
  template \
  --namespace 'my-namespace' \
  --name-template 'collection' \
  --set sumologic.accessId='<ACCESS_KEY>' \
  --set sumologic.accessKey='<ACCESS_ID>' \
  --set sumologic.clusterName='<CLUSTER_NAME>' \
  | tee sumologic.yaml
```

Finally, you can run `kubectl apply` on the file containing the rendered YAML from the previous step. You must change your `kubectl` context to the namespace you wish to install in.

```bash
kubectl config set-context --current --namespace=my-namespace
kubectl apply -f sumologic.yaml
```

## Viewing Data In Sumo Logic

Once you have completed installation, you can [install the Kubernetes App and view the dashboards](https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App_and_view_the_Dashboards) or [open a new Explore tab](https://help.sumologic.com/Solutions/Kubernetes_Solution/05Navigate_your_Kubernetes_environment) in Sumo Logic. If you do not see data in Sumo Logic, you can review our [troubleshooting guide](./Troubleshoot_Collection.md).

## Troubleshooting Installation

### Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists
If you get `Error: customresourcedefinitions.apiextensions.k8s.io "alertmanagers.monitoring.coreos.com" already exists` it means you did not apply the CRD's yet.  Please make sure you apply CRD's before rendering as documented above.

### Fluentd Pods Stuck in CreateContainerConfigError
If the fluentd pods are in `CreateContainerConfigError` it can mean the setup job has not completed yet. Wait for the setup pod to complete and the issue should resolve itself.  The setup job creates a secret and the error simply means the secret is not there yet.  This usually resolves itself automatically.

If the issue does not solve resolve automatically, you will need to look at the logs for the setup pod. Kubernetes schedules the job in a pod, so you can look at logs from the pod to see why the job is failing. First find the pod name in the namespace where the Helm chart was deployed. The pod name will contain `-setup` in the name.

```sh
kubectl get pods
```

Get the logs from that pod:
```
kubectl logs POD_NAME -f
```

### Error: collector with name 'sumologic' does not exist
If you get `Error: collector with name 'sumologic' does not exist
sumologic_http_source.default_metrics_source: Importing from ID`, you can safely ignore it and the installation should complete successfully. The installation process creates new [HTTP endpoints](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in your Sumo Logic account, that are used to send data to Sumo. This error occurs if the endpoints had already been created by an earlier run of the installation process.

You can find more information in our [troubleshooting documentation](Troubleshoot_Collection.md).

## Customizing Installation
All default properties for the Helm chart can be found in our [documentation](HelmChartConfiguration.md). We recommend creating a new `values.yaml` for each Kubernetes cluster you wish to install collection on and **setting only the properties you wish to override**. Once you have customized the file you can generate the YAML. When using a `values.yaml` you will create a `ConfigMap` to store the file.
  
```bash
kubectl create configmap sumologic-values --from-file=values.yaml
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-tools/master/src/k8s/tools-pod.yaml -s | kubectl apply -f -
kubectl exec sumologic-tools \
  -- \
  template \
  --name-template 'collection' \
  -f /values.yaml \
  | tee sumologic.yaml
kubectl delete pod sumologic-tools
kubectl delete configmap sumologic-values
``` 

> **Tip**: To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Upgrading Sumo Logic Collection

**Note, if you are upgrading to version 1.x of our collection from a version before 1.x, please see our [migration guide](v1_migration_doc.md).**

To upgrade you can simply re-generate the YAML when a new version of the Kubernetes collection is available.  If you with to upgrade to a specific version, you can pass the `--version` flag when generating the YAML.

```bash
kubectl run tools \
  -it --quiet --rm \
  --restart=Never \
  --image sumologic/kubernetes-tools -- \
  template \
  --namespace 'my-namespace' \
  --name-template 'collection' \
  --set sumologic.accessId='<ACCESS_KEY>' \
  --set sumologic.accessKey='<ACCESS_ID>' \
  --set sumologic.clusterName='<CLUSTER_NAME>' \
  --version=1.0.0
  | tee sumologic.yaml
```

## Uninstalling Sumo Logic Collection

To uninstall/delete, simply kube `kubectl delete` on the generated YAML.

```bash
kubectl delete -f sumologic.yaml
```

To remove the Kubernetes secret:

```bash
kubectl delete secret sumologic
```

Then delete the associated hosted collector in the Sumo Logic UI.