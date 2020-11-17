# Authenticating with container registry

Sumo Logic docker images used in the collection are currently hosted on hub.docker.com which
[requires authentication in order to provide higher quota for image pulls][docker-rate-limit].

In order to authenticate with docker registry hosted at hub.docker.com when using
helm installation one can use `sumologic.pullSecrets`, to pass kubernetes secret
names which contain the required credentials.

Creating aforementioned secret is beyond the scope of this document.
Extensive documentation on this subject can be found at
[Creating a Secret with a Docker config at kubernetes.io][k8s-docker-secret].

[docker-rate-limit]: https://www.docker.com/increase-rate-limits
[k8s-docker-secret]: https://kubernetes.io/docs/concepts/containers/images/#creating-a-secret-with-a-docker-config