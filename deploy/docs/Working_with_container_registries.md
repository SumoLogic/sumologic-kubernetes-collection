# Working with container registries

## Authenticating with container registry

Sumo Logic container images used for collection are currently hosted on
[Docker Hub](https://hub.docker.com/) which
[requires authentication to provide a higher quota for image pulls][docker-rate-limit].

In order to authenticate with the container registry hosted on
[Docker Hub](https://hub.docker.com/) when using helm installation you can use
`sumologic.pullSecrets` to pass Kubernetes secret names that contain
the required credentials.

Creating aforementioned secret is beyond the scope of this document.
Extensive documentation on this subject can be found at
[Creating a Secret with a Docker config at kubernetes.io][k8s-docker-secret].

[docker-rate-limit]: https://www.docker.com/increase-rate-limits
[k8s-docker-secret]: https://kubernetes.io/docs/concepts/containers/images/#creating-a-secret-with-a-docker-config

## Hosting Sumo Logic images

Another approach to work around [Docker Hub](https://hub.docker.com/) limits is
to host Sumo Logic images in one's own container registry.

Describing how to push images or how to authenticate with many different container
registries is beyond the scope of this document but in general instructions can
be narrowed down to:

```
docker pull sumologic/kubernetes-fluentd:${SUMO_IMAGE_VERSION}
docker tag sumologic/kubernetes-fluentd:${SUMO_IMAGE_VERSION} ${REGISTRY_REPO_URL}:${VERSION}
docker push ${REGISTRY_REPO_URL}:${VERSION}
```

One can then use `${REGISTRY_REPO_URL}:${VERSION}` in `values.yaml` as such:

```yaml
image:
  repository: ${REGISTRY_REPO_URL}
  tag: ${VERSION}
  pullPolicy: IfNotPresent
```
