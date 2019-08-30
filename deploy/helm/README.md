# Sumo Logic Helm Chart
| DISCLAIMER |
| --- |
| This Helm chart is still under development. |

## Introduction

This chart deploys Kubernetes resources for collecting Kubernetes logs, metrics, and events; enriching them with deployment, pod, and service level metadata; and sending them to Sumo Logic.

## Prerequisite

Before installing the chart, you'll need to run the provided `setup.sh` script. It will create a namespace called `sumologic` and a secret with the same name that contains the Sumo Logic collection endpoints.

To run the script that creates the namespace and secret, use the following command:

```bash
curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/kubernetes/setup.sh \
  | bash -s - -d false -y false <api_endpoint> <access_id> <access_key>
```
NOTE: You'll need to set `-d` and `-y` to false so the script does not download the YAML file or deploy the resources into your cluster yet. Details on the parameters are explained [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/master/deploy#automatic-source-creation-and-setup-script). 

_Soon this step will not be needed after we move the collection setup into a helm hook. Stay tuned._

## Installing the Chart

To install the chart, first add the `sumologic` private repo:

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

Install the chart with release name `collection` and namespace `sumologic`
```bash
helm install sumologic/sumologic --name collection --namespace sumologic
```

NOTE: If you install the chart with a different release name or a different namespace, you will need to override remote write URLs for Prometheus and the host for fluent-bit. We recommend using an override file due to the number of URLs that need to be overridden. You can use the following command to download the override file and replace the `<RELEASE-NAME>` and `<NAMESPACE>`:
  
```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml | \
sed 's/\-sumologic.sumologic'"/-sumologic.<NAMESPACE>/g" | \
sed 's/\collection'"/<RELEASE-NAME>/g" > values.yaml
```

For example, if your release name is `my-release` and namespace is `my-namespace`:
```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/helm/sumologic/values.yaml | \
sed 's/\-sumologic.sumologic'"/-sumologic.my-namespace/g" | \
sed 's/\collection'"/my-release/g" > values.yaml
```

Then, install the chart with the override file.
```bash
helm install sumologic/sumologic --name my-release --namespace my-namespace -f values.yaml
```


> **Tip**: List all releases using `helm list`, a release is a name used to track a specific deployment

## Uninstalling the Chart

To uninstall/delete the `collection` release:

```bash
helm delete collection
```
> **Tip**: Use helm delete --purge collection to completely remove the release from Helm internal storage

The command removes all the Kubernetes components associated with the chart and deletes the release.
