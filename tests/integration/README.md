# sumologic-kubernetes-collection integration tests

This directory contains `sumologic-kubernetes-collection` integration tests utilizing:

- [`kind`][kind]
- [`terratest`][terratest]
- [`kubernetes_e2e_framework`][kubernetes_e2e_framework]

[terratest]: https://github.com/gruntwork-io/terratest
[kubernetes_e2e_framework]: https://github.com/kubernetes-sigs/e2e-framework
[kind]: https://kind.sigs.k8s.io/

---

- [Quickstart](#quickstart)
- [Using pre-existing clusters](#using-pre-existing-clusters)
  - [Creating `kind` cluster](#creating-kind-cluster)
  - [Reusing a preexisting cluster](#reusing-a-preexisting-cluster)
- [Runtime options](#runtime-options)
- [Filtering tests](#filtering-tests)
  - [Running specific tests](#running-specific-tests)
  - [Running specific features/assessments](#running-specific-featuresassessments)
- [K8s node images matrix](#k8s-node-images-matrix)
- [Known limitations/issues](#known-limitationsissues)
  - [Maximum size of arguments for processes](#maximum-size-of-arguments-for-processes)

---

## Quickstart

Running tests should be as simple as running:

```shell
make test
```

in this directory.

This will:

- create `kind` cluster for each test
  - on CI this will create a new cluster for each test and for each k8s version as defined in [kind_images.json](./kind_images.json)
  - see [Reusing a preexisting cluster](#reusing-a-preexisting-cluster) in order to reuse a cluser
- run the tests (using Go toolchain i.e. `go test ....`)
- destroy created `kind` cluster(s)

> **NOTE**: There is an assumption about mapping tests to helm values files.
>
> In order to keep the model of "one `kind` cluster per one test" we map the test name (details can be found in
> [`strings.ValueFileFromT()`](./internal/strings/strings.go)) )
>
> Because of that the author of a test is supposed to create a values file in `values/` directory which will map to his/hers test name.
>
> Exemplar mapping:
>
> | Test name                       | Values file path                              |
> | ------------------------------- | --------------------------------------------- |
> | `Test_Helm_Default_OT_Metadata` | `values/values_helm_default_ot_metadata.yaml` |

## Using pre-existing clusters

You should pay special care when reusing clusters across test runs since left over artifacts in clusters might cause false positives or
false negatives in test results.

### Creating `kind` cluster

You can use the `create-cluster` make target in order to create a cluster and reuse it on subsequent tests runs to save time.

After you're done with the cluster, `delete-cluster` can be used in order to remove it.

### Reusing a preexisting cluster

In order to use a preexisting cluster you can use:

- `USE_KUBECONFIG` which when set to anything else than an empty string indicates that tests should not create a cluster but use a
  pre-existing one
- `KUBECONFIG` which indicates the location of kubeconfig to be used for tests

Example:

```shell
USE_KUBECONFIG=1 KUBECONFIG=/tmp/xm1r7h7s7 make test
```

> **NOTE**: The preexisting cluster that's being used for tests does not have to be a `kind` cluster.

## Preloading docker images into the cluster

A significant chunk of the runtime of these tests involves the cluster pulling the necessary docker images. In particular, this can make
running the tests on slower internet connections rather painful. Thankfully, `kind` provides a mechanism to preload both individual docker
images and multi-image archives into the cluster at runtime from the host.

We provide a Makefile target for generating a docker image archive from the Helm values used:

```bash
make create-image-archive
```

Running the above will create an `images.tar` file in this directory, which the tests will automatically make use of.

### Using a custom image archive file

It's possible to change the image archive file name:

```bash
make create-image-archive IMAGE_ARCHIVE=/my/file.tar
IMAGE_ARCHIVE=/my/file.tar make test
```

## Runtime options

The test framework has the following runtime options that can be utilized:

- `HELM_NO_DEPENDENCY_UPDATE` - when set to anything else than an empty string will cause the helm tests to not run
  `helm dependency update`. This can be used to speed up tests execution when appropriate (up to date) helm dependencies are already present
  on the system

  Example:

  ```shell
  HELM_NO_DEPENDENCY_UPDATE=1 make test
  ```

## Filtering tests

[Testing framework][sig_e2e_testing_harness] that's used in the tests allows filtering tests by feature names, labels and step names.

This might be handy if you'd like to use those abstractions but its consequence is that it will run all the code related to setup and/or
teardown so e.g. all kind clusters that were supposed to be created for tests that got filtered out would be created anyway.

### Running specific tests

In order to run specific tests you can use `go` related test filtering like so:

```shell
make test TEST_NAME="Test_Helm_Default"
```

or

```shell
go test -v -count 1 -run=Test_Helm_Default .
```

### Running specific features/assessments

In order to run specific features you can use `TEST_ARGS` makefile argument in which you can specify [e2e framework's
flags][sig_e2e_testing_harness_filtering_tests]:

```shell
make test TEST_NAME="Test_Helm_Default_OT_Metadata" TEST_ARGS="--assess '(metrics)'"
```

or

```shell
make test TEST_NAME="Test_Helm_Default_OT_Metadata" TEST_ARGS="--feature '(installation)'"
```

[sig_e2e_testing_harness]: https://github.com/kubernetes-sigs/e2e-framework/blob/main/docs/design/test-harness-framework.md
[sig_e2e_testing_harness_filtering_tests]:
  https://github.com/kubernetes-sigs/e2e-framework/blob/fee1391aeccdc260069bd5e0b25c6b187c2293c4/docs/design/test-harness-framework.md#filtering-feature-tests

## K8s node images matrix

Node images (k8s versions) on which tests are being run are defined in [`kind_images.json`](./kind_images.json) and have the following
structure:

```json
{
  "supported": [
    ...
    "kindest/node:v1.25.3",
    "kindest/node:v1.23.6"
   ],
  "default": "kindest/node:v1.25.3"
}
```

Where `.default` sets what is being used by default and `.supported` indicates on which images the tests should pass - CI configuration will
ensure that tests are being on each of those image versions.

## Known limitations/issues

### Maximum size of arguments for processes

Maximum size of arguments for processes is limited by:

- `ARG_MAX` - maximum length of arguments
- `MAX_ARG_STRLEN` - maximum size for one argument

**Note**: `ARG_MAX` and `MAX_ARG_STRLEN` vary on different systems.

Because of limited size of arguments it is not possible to prepare Pod with very long list of arguments which is generated in the code, e.g.
Pod with very long list of `echo` commands that have very long string passed as an argument.

When process receives too long list of arguments following error occurs:

```
2022-02-22T13:57:55.662403778Z stderr F standard_init_linux.go:228: exec user process caused: argument list too long
```

To learn more about `ARG_MAX` and `MAX_ARG_STRLEN` please read [ARG_MAX, maximum length of arguments for a new process][arg_max_article]

[arg_max_article]: https://www.in-ulm.de/~mascheck/various/argmax/#maximum_number
