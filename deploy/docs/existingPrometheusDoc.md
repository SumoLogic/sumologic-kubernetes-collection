# How to install if you have an existing Prometheus operator

__NOTE__: The Sumo Logic Kubernetes collection process does not support collecting metrics from scaling Prometheus replicas. If you are running multiple Prometheus replicas, please follow our [Side-by-Side](SideBySidePrometheus.md) instructions.

This document will walk you through how to setup Sumo Logic Kubernetes collection when you already have Prometheus running using the Prometheus Operator. In these steps, you will modify your installed Prometheus operator to add in the minimum configuration that Sumo Logic needs.

If you do not wish to modify your Prometheus Operator and wish to run side-by-side with our collection, please refer to our [How to install our Prometheus side by side with your existing Prometheus](./SideBySidePrometheus.md) documentation.

## Install Sumo Logic Helm Chart

The Helm chart installation requires two parameter overrides:
* __sumologic.accessId__ - Sumo [Access ID](https://help.sumologic.com/Manage/Security/Access-Keys).
* __sumologic.accessKey__ - Sumo [Access key](https://help.sumologic.com/Manage/Security/Access-Keys).

The following parameter is optional, but we recommend setting it.
* __sumologic.clusterName__ - An identifier for your Kubernetes cluster.  This is the name you will see for the cluster in Sumo Logic. Default is `kubernetes`.

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Next you can run `helm upgrade --install` to install our chart.  An example command with the minimum parameters is provided below.  The following command will install the Sumo Logic chart with the release name `my-release` in the namespace your `kubectl` context is currently set to. The below command also disables the `prometheus-operator` sub-chart since we will be modifying the existing prometheus operator install.

```bash
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false
```
> **Note**: This command is compatible with Helm2 or Helm3.  If the release exists, it will be upgraded, otherwise it will be installed.

If you wish to install the chart in a different namespace you can do the following:

**Helm2**
```bash
helm upgrade --install my-release sumologic/sumologic --namespace=my-namespace --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false
```

Please note that Helm3 no longer supports the namespace flag. You must change your `kubectl` context to the namespace you wish to install in.

**Helm3**
```bash
kubectl config set-context --current --namespace=my-namespace
helm upgrade --install my-release sumologic/sumologic --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY>  --set sumologic.clusterName="<MY_CLUSTER_NAME>" --set prometheus-operator.enabled=false
```

## Update Existing Prometheus Operator Helm Chart

**Note that If you have made extensive customization to the current Prometheus Operator Helm install then you will need to [merge your existing configuration with ours](#merge-prometheus-configuration) avoiding conflicts or you may want to [run our Prometheus side-by-side](./SideBySidePrometheus.md).**

Next you will modify your Prometheus Operator installation with the required configuration to collect the metrics into Sumo Logic. Please note that this process is best when you have not customized the existing Prometheus Operator installation.  If you have, please look at [our section on merging the configuration](#merge-prometheus-configuration).

If the Prometheus Operator is installed in a different namespace as compared to where the Sumo Logic Chart is deployed, you would need to do the following step to copy the `ConfigMap` that exposes the release name,  which is used in the remote write urls.

For example:\
If the Sumo Logic Solution is deployed in `<source-namespace>` and the existing prometheus-operator is in `<destination-namespace>`, run the below command:
```bash
kubectl get configmap sumologic-configmap \
--namespace=<source-namespace> --export -o yaml | \
kubectl apply --namespace=<destination-namespace> -f -
```

Run the following commands to update the [remote write configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write) of the prometheus operator with the prometheus overrides we provide in our [prometheus-overrides.yaml](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/helm/prometheus-overrides.yaml).

Run the following command to download our prometheus-overrides.yaml file.  Please review our configuration as it will be applied to your existing operator configuration.

```bash
curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v1.0/deploy/helm/prometheus-overrides.yaml
```

Next you can upgrade your Prometheus-Operator.  The following command assumes it is installed with the release name `prometheus-operator`. Remember, this command will update your Prometheus Operator to be configured with our default settings.   

```bash
helm upgrade prometheus-operator stable/prometheus-operator -f prometheus-overrides.yaml 
```

## Merge Prometheus Configuration

If you have customized your Prometheus configuration, follow these steps to merge the configurations. 

Helm supports providing multiple configuration files, and priority will be given to the last (right-most) file specified. You can obtain your current prometheus configuration by running

```bash
helm get values prometheus-operator > current-values.yaml
```

Any section of `current-values.yaml` that conflicts with sections of our `prometheus-overrides.yaml` will have to be removed from the `prometheus-overrides.yaml` file and appended to `current-values.yaml` in relevant sections. For any config that doesn’t conflict, you can leave them in `prometheus-overrides.yaml`. Then run

```bash
helm upgrade prometheus-operator stable/prometheus-operator -f current-values.yaml -f prometheus-overrides.yaml
```

__NOTE__ To filter or add custom metrics to Prometheus, [please refer to this document](additional_prometheus_configuration.md)

## Troubleshooting

### UPGRADE FAILED: failed to create resource: Internal error occurred: failed calling webhook "prometheusrulemutate.monitoring.coreos.com"

If you receive the above error, you can take the following steps and then repeat the `helm upgrade` command.

```bash
kubectl delete  validatingwebhookconfigurations.admissionregistration.k8s.io prometheus-operator-admission
kubectl delete  MutatingWebhookConfiguration  prometheus-operator-admission
```