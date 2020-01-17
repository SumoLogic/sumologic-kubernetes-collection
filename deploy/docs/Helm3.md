# Using this chart with Helm 3

Helm 3 can be used to install the Sumo Logic Helm chart.

## Migrating from Helm2 to Helm 3

If you have installed our Helm chart with Helm 2 and are looking to migrate to Helm 3, we recommend following this [migration guide](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/) to transition your Helm 2 release of the Sumo Logic chart.

## Installing Chart Using Helm 3

If you are currently using Helm 3 use the following steps to install the chart.

  1. Helm 3 no longer creates namespaces. You will need to create a Sumo Logic namespace first.
  
```
kubectl create namespace sumologic
```

  2. Change your kubectl context to the sumologic namespace. You can use a tool like [kubens](https://github.com/ahmetb/kubectx) or kubectl to do this.
  
```bash
kubectl config set-context --current --namespace=sumologic
```

  3. Install the chart using Helm 3. The helm install command has changed slightly in Helm 3.
  
```
helm install collection sumologic/sumologic  --set sumologic.endpoint=<SUMO_API_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> --set prometheus-operator.prometheus.prometheusSpec.externalLabels.cluster="<MY_CLUSTER_NAME>" --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

NOTE: You may see the following messages however they can usually be ignored.

```bash
manifest_sorter.go:175: info: skipping unknown hook: "crd-install"
manifest_sorter.go:175: info: skipping unknown hook: "crd-install"
manifest_sorter.go:175: info: skipping unknown hook: "crd-install"
manifest_sorter.go:175: info: skipping unknown hook: "crd-install"
manifest_sorter.go:175: info: skipping unknown hook: "crd-install"
```

NOTE: If you need to install the chart with a different release name or namespace you will need to override some configuration fields for both Prometheus and fluent-bit. We recommend using an override file due to the number of fields that need to be overridden. In the following command, replace the `<RELEASE-NAME>` and `<NAMESPACE>` variables with your values and then run it to download the override file with your replaced values:

```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml | \
sed 's/\-sumologic.sumologic'"/-sumologic.<NAMESPACE>/g" | \
sed 's/\- sumologic'"/- <NAMESPACE>/g" | \
sed 's/\collection'"/<RELEASE-NAME>/g" > values.yaml
```

For example, if your release name is `my-release` and namespace is `my-namespace`:
```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml | \
sed 's/\-sumologic.sumologic'"/-sumologic.my-namespace/g" | \
sed 's/\collection'"/my-release/g" > values.yaml
```

Make any changes to the `values.yaml` file as needed and then change your kubectl context to the desired namespace.

```bash
kubectl config set-context --current --namespace=my-namespace
```
 
Then you can run the following to install the chart with the override file.

```bash
helm install my-release sumologic/sumologic -f values.yaml --set sumologic.endpoint=<SUMO_API_ENDPOINT> --set sumologic.accessId=<SUMO_ACCESS_ID> --set sumologic.accessKey=<SUMO_ACCESS_KEY> 
```

## Uninstalling Chart Using Helm 3

In Helm 3 the delete command has changed slightly. By default, history is not preserved yet can be retained by using `--keep-history`

  * Delete without preserving history
  
```bash
helm del collection
```

  * Delete and preserve history
  
```bash
helm del --keep-history collection
```
