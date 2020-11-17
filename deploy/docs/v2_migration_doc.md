# Kubernetes Collection `v2.0.0` - Breaking Changes

- [Changes](#changes)
- [How to upgrade](#how-to-upgrade)

Based on the feedback from our users, we will be introducing several changes
to the Sumo Logic Kubernetes Collection solution.
Here we detail the changes for both Helm and Non-Helm users, as well as
the exact steps for migration.

## Changes

- Version `v2.0.0` is dropping support for Helm 2.

- We've been using `kube-prometheus-stack` with an alias `prometheus-operator` since `v1.3.0`
  to not introduce any breaking changes but with `v2.0.0` we're removing the alias,
  hence all the options related to this dependency should be prefixed with
  `kube-prometheus-stack` instead of `prometheus-operator`.

- When upgrading `kube-prometheus-stack` from `v9.x` to `v12.y`, apart from changing
  below mentioned configuration parameters one has to also install new prometheus
  CRDs.
  This can be done with the following commands:

  ```bash
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
  kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.43/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
  ```

- Changes in Configuration Parameters
  - `kube-prometheus-stack` dependency has been updated from `v9.3.4` to `v12.0.1`
    which causes the following configuration options to need migrating:

    | Old Config | New Config |
    |:---:|:--:|
    | `kube-prometheus-stack.prometheusOperator.tlsProxy` | `kube-prometheus-stack.prometheusOperator.tls` |

  - `prometheus-config-reloader` has been removed from the list of containers
    that can be run as part of prometheus statefulset and has been replaced with
    `config-reloader`, hence the following

    ```yaml
    kube-prometheus-spec:
      ...
      prometheus:
        ...
        prometheusSpec:
          ...
          containers:
          - name: "prometheus-config-reloader"
    ```

    has to be changed into:

    ```yaml
    kube-prometheus-spec:

      ...
      prometheus:
        ...
        prometheusSpec:
          ...
          containers:
          - name: "config-reloader"
    ```

## How to upgrade

**Note: The below steps are using Helm 3. Helm 2 is not supported.**
