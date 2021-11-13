# sumologic-kubernetes-collection integration tests

This directory contains `sumologic-kubernetes-collection` integration tests utilizing:

- [`kind`][kind]
- [`terratest`][terratest]
- [`kubernetes_e2e_framework`][kubernetes_e2e_framework]

[terratest]: https://github.com/gruntwork-io/terratest
[kubernetes_e2e_framework]: https://github.com/kubernetes-sigs/e2e-framework
[kind]: https://kind.sigs.k8s.io/

## Quickstart

Running tests should be as simple as running:

```shell
make test
```

in this directory.

This would:

- create `kind` cluster(s) for tests as necessary
- run the tests (using Go toolchain i.e. `go test ....`)
- destroy created `kind` cluster(s)

## Using pre-existing clusters

One should pay special care when reusing clusters across test runs since left over
artifacts in clusters might cause false positives or false negatives in test results.

### Creating `kind` cluster

One can use the `create-cluster` make target in order to create a cluster and reuse
it on subsequent tests runs to save time.

After one's done with the cluster, `delete-cluster` can be used in order to remove it.

### Reusing a preexisting cluster

In order to use a preexisting cluster one can use:

- `USE_KUBECONFIG` which when set to anything else than an empty string indicates that
  tests should not create a cluster but use a pre-existing one
- `KUBECONFIG` which indicates the location of kubeconfig to be used for tests

Example:

```shell
USE_KUBECONFIG=1 KUBECONFIG=/tmp/xm1r7h7s7 make test
```

> **NOTE**: The preexisting cluster that's being used for tests does not have
> to be a `kind` cluster.

## Runtime options

The test framework has the following runtime options that can be utilized:

- `HELM_NO_DEPENDENCY_UPDATE` - when set to anything else than an empty string
  will cause the helm tests to not run `helm dependency update`. This can be used to
  speed up tests execution when appropriate (up to date) helm dependencies are
  already present on the system

  Example:

  ```shell
  HELM_NO_DEPENDENCY_UPDATE=1 make test
  ```

## K8s node images matrix

Node images (k8s versions) on which tests are being run are defined in
[`kind_images.json`](./kind_images.json) and have the following structure:

```json
{
  "supported": [
    ...
    "kindest/node:v1.21.2@sha256:9d07ff05e4afefbba983fac311807b3c17a5f36e7061f6cb7e2ba756255b2be4",
    "kindest/node:v1.22.4@sha256:d3c56a1a9e3bb93e44be546fb71ed81a748f412d5f173bf8459ee2e3e58930d8"
   ],
  "default": "kindest/node:v1.21.2@sha256:9d07ff05e4afefbba983fac311807b3c17a5f36e7061f6cb7e2ba756255b2be4"
}
```

Where `.default` sets what is being used by default and `.supported` indicates on which
images the tests should pass - CI configuration will ensure that tests are being on
each of those image versions.
