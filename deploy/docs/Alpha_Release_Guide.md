# Alpha Releases

| DISCLAIMER |
| --- |
| We recommend testing alpha releases on non-production clusters. These releases are generated continuously from contributions to this repo and may not be fully tested. |

As part of our [Travis CI script](../../ci/build.sh), we release an alpha Docker image as well as an alpha Helm chart release.

## Versioning
Release Type | Version Scheme | Example
-------- | ----- | -----
Major Release | `major.0.0` | `2.0.0`
Minor Release | `major.minor.0` | `0.11.0`
Alpha Release | `major.minor.patch-alpha` | `0.11.3-alpha`

You can find a list of all releases in the Github repo's [Releases](https://github.com/SumoLogic/sumologic-kubernetes-collection/releases) section. You can find a list of all Docker images in the [Docker tags](https://hub.docker.com/repository/docker/sumologic/kubernetes-fluentd/tags) section.

## Using an alpha release

### Helm installation

Follow the [Helm installation guide](./Installation_with_Helm.md), but override both the Helm chart version and the Docker image version.

```
helm repo update
helm install collection sumologic/sumologic --namespace sumologic --create-namespace ... --version=0.11.3-alpha --set image.tag="0.11.3-alpha"
```

### Non-helm installation

Follow the [non-Helm installation guide](./Non_Helm_Installation.md), but modify the .yaml template to use an alpha Docker image for both log and event deployments, e.g.

```
- name: fluentd
  image: sumologic/kubernetes-fluentd:0.11.3-alpha
```

```
- name: fluentd-events
  image: sumologic/kubernetes-fluentd:0.11.3-alpha
```
