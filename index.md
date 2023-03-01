# Sumo Logic Helm Repository

![Sumologic](https://sumologic.github.io/sumologic-kubernetes-collection/images/overview-v3.png)

## Add the Sumo Logic Helm repository

```bash
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

## Install Sumo Logic Helm Chart

```bash
helm upgrade --install my-release sumologic/sumologic \
    --set sumologic.accessId="<SUMO_ACCESS_ID>" \
    --set sumologic.accessKey="<SUMO_ACCESS_KEY>" \
    --set sumologic.clusterName="<MY_CLUSTER_NAME>"
```

Above command will install the Sumo Logic Helm Chart with the release name `my-release` in the namespace your `kubectl` context is currently set to.

For more details please see [sumologic-kubernetes-collection](https://github.com/SumoLogic/sumologic-kubernetes-collection) repository.
