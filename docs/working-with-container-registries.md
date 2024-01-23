# Working with container registries

## Authenticating with container registry

Sumo Logic container images used for collection are currently hosted on [Amazon Public ECR][aws-public-ecr-docs] which requires
authentication to provide a higher quota for image pulls. To find a comprehensive information on this please refer to [Amazon Elastic
Container Registry pricing][aws-ecr-pricing].

In order to authenticate with AWS Public ECR (to prevent hitting unauthenticated pulls quota) when using helm installation one can use
`sumologic.pullSecrets` to pass Kubernetes secret names that contain the required credentials.

Secret with registry credentials can be created using the following commands:

```
kubectl create secret docker-registry ${SECRET_NAME} \
  --docker-server=public.ecr.aws \
  --docker-username=AWS \
  --docker-password=$(aws ecr-public --region us-east-1 get-login-password)
```

After creating the secret one can use it in the following way:

```yaml
sumologic:
  ...
  pullSecrets:
    - name: ${SECRET_NAME}
```

For more information on using Kubernetes secrets with container registries please refer to [Creating a Secret with a Docker config at
kubernetes.io][k8s-docker-secret].

[aws-public-ecr-docs]: https://aws.amazon.com/blogs/aws/amazon-ecr-public-a-new-public-container-registry/
[k8s-docker-secret]: https://kubernetes.io/docs/concepts/containers/images/#creating-a-secret-with-a-docker-config
[aws-ecr-pricing]: https://aws.amazon.com/ecr/pricing/

## Using pull secrets with `sumologic-kubernetes-collection` helm chart

Full list of `user-values.yaml` keys for all the images that are used, can be found below:

| Image                 | `user-values.yaml` key                          |
| --------------------- | ----------------------------------------------- |
| setup job             | `sumologic.setup.job.pullSecrets`               |
| Sumo Logic OT distro  | `sumologic.pullSecrets`                         |
| remote-write-proxy    | `sumologic.pullSecrets`                         |
| kube-prometheus-stack | `kube-prometheus-stack.global.imagePullSecrets` |
| metrics-server        | `metrics-server.image.pullSecrets`              |
| telegraf-operator     | `telegraf-operator.imagePullSecrets`            |
| falco                 | `falco.image.pullSecrets`                       |

## Hosting Sumo Logic images

Another approach to work around Amazon Public ECR limits is to host Sumo Logic images in one's own container registry.

Describing how to push images or how to authenticate with many different container registries is beyond the scope of this document but in
general instructions can be narrowed down to:

```
docker pull public.ecr.aws/sumologic/sumologic-otel-collector:${SUMO_IMAGE_VERSION}
docker tag public.ecr.aws/sumologic/sumologic-otel-collector:${SUMO_IMAGE_VERSION} ${REGISTRY_REPO_URL}:${TAG}
docker push ${REGISTRY_REPO_URL}:${TAG}
```

One can then use `${REGISTRY_REPO_URL}:${TAG}` in `user-values.yaml` as such:

```yaml
sumologic:
  otelcol:
    defaultImage:
      tag: 0.92.0-sumo-0-fips
```

## Upgrading while rehosting images

New versions of the Helm chart can include updating the default container image versions. When using a custom container registry, we
strongly recommend updating the version to be in-line with the defaults. The [changelog][changelog] and [release notes][release_notes] will
always mention these kinds of updates and can safely be used as a guiding tool when upgrading.

[changelog]: /CHANGELOG.md
[release_notes]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases
