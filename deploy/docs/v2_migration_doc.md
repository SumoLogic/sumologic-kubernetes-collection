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
  - `kube-prometheus-stack` dependency has been updated from `v9.x` to `v12.y`
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

- We've separated our fluentd image from setup job image, hence `image` was migrated
  to `sumologic.setup.job.image` and to `fluentd.image`

- `sumologic.sources` become `sumologic.collector.sources` as Sources are being
  created under Collectors

- `sumologic.setup.fields` become `sumologic.collector.fields` as Fields are
  set on a Collector

## How to upgrade

**Note: The below steps are using Helm 3. Helm 2 is not supported.**

### 1. Upgrade to helm chart version `v1.3.2`

#### Ensure you have sumologic helm repo added

Before running commands shown below please make sure that you have
sumologic helm repo configured.
One can check that using:

```
helm repo list
NAME                    URL
...
sumologic               https://sumologic.github.io/sumologic-kubernetes-collection
...
```

If sumologic helm repo is not configured use the following command to add it:

```
helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```

#### Update

Run the command shown below to fetch the latest helm chart:

```bash
helm repo update
```

For users who are not already on `v1.3.2` of the helm chart, please upgrade
to that version first by running the below command:

```bash
helm upgrade collection sumologic/sumologic --reuse-values --version=1.3.2
```

### 2. Upgrade Prometheus CRDs

Due to changes in `kube-prometheus-stack` which this chart depends on, one will
need to run the following commands in order to update Prometheus related CRDs.

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

### 3. Run upgrade script

For Helm users, the only breaking changes are the renamed config parameters.
For users who use a `values.yaml` file, we provide a script that users can run
to convert their existing `values.yaml` file into one that is compatible with the major release.

- Get the existing values for the helm chart and store it as `current_values.yaml`
  with the below command:

  ```bash
  helm get values <RELEASE-NAME> > current_values.yaml
  ```

- Download the upgrade script via:

  ```bash
  curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/main/deploy/helm/sumologic/upgrade-2.0.0.sh
  ```

- Run the upgrade script on the above file with the below command.

  ```bash
  chmod +x upgrade-2.0.0.sh && ./upgrade-2.0.0.sh current_values.yaml
  ```

- At this point, users can then run:

  ```bash
  helm upgrade collection sumologic/sumologic --version=2.0.0 -f new_values.yaml
  ```
