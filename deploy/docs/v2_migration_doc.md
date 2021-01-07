# Kubernetes Collection `v2.0.0` - Breaking Changes

- [Changes](#changes)
- [How to upgrade](#how-to-upgrade)

Based on the feedback from our users, we will be introducing several changes
to the Sumo Logic Kubernetes Collection solution.

In this document we detail the changes for both Helm and Non-Helm users,
as well as the exact steps for migration.

## Changes

- Version `v2.0.0` is dropping support for Helm 2.

- `kube-prometheus-stack` has been used in this chart since version `v1.3.0`
  using an alias `prometheus-operator` in order not to introduce any breaking
  changes (before that version, prometheus stack was provided by `prometheus-operator`
  chart).
  In `v2.0.0` this alias is being removed hence all the options related to this
  dependency should be prefixed with `kube-prometheus-stack` instead of
  `prometheus-operator`.

- When upgrading `kube-prometheus-stack` from `v9.x` to `v12.y`, apart from changing
  below mentioned configuration parameters one has to also install new prometheus
  CRDs.
  This can be done using the code snippet mentioned in
  [Upgrade Prometheus CRDs](#2-upgrade-prometheus-crds)

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

- `spec.selector` in Fluent Bit Helm Chart was modified from:

  ```yaml
  spec:
  selector:
    matchLabels:
      app: fluent-bit
      release: <RELEASE-NAME>
  ```

  to

  ```yaml
  spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: fluent-bit
      app.kubernetes.io/instance: <RELEASE-NAME>
  ```

## How to upgrade

### Requirements

- helm3
- yq in version: `3.4.0` <= `x` < `4.0.0`
- bash 4.0 or higher

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

### 3. Prepare Fluent Bit instance

As `spec.selector` in Fluent Bit Helm chart was modified, it is required to manually recreate or delete existing DaemonSet
with old version of `spec.selector` before upgrade.

One of the following two strategies can be used:

- #### Recreating Fluent Bit DaemonSet

  Recreating Fluent Bit DaemonSet with new `spec.selector` may cause that applications' logs and Fluent Bit metrics
  will not be available in the time of recreation. It usually shouldn't take more than several seconds.

  To recreate the Fluent Bit DaemonSet with new `spec.selector` one can run the following command:

  ```bash
  kubectl get daemonset --namespace <NAMESPACE-NAME> --selector "app=fluent-bit,release=<RELEASE-NAME>" --output yaml | \
  yq w - "items[*].spec.selector.matchLabels[app.kubernetes.io/name]" "fluent-bit" | \
  yq w - "items[*].spec.selector.matchLabels[app.kubernetes.io/instance]" "<RELEASE-NAME>" | \
  yq w - "items[*].spec.template.metadata.labels[app.kubernetes.io/name]" "fluent-bit" | \
  yq w - "items[*].spec.template.metadata.labels[app.kubernetes.io/instance]" "<RELEASE-NAME>" | \
  yq d - "items[*].spec.selector.matchLabels[app]" | \
  yq d - "items[*].spec.selector.matchLabels[release]" | \
  kubectl apply --namespace <NAMESPACE-NAME>  --force --filename -
  ```

- #### Preparing temporary instance of Fluent Bit

  Create temporary instance of Fluent Bit and delete DaemonSet with old version of `spec.selector`.
  This will cause application' logs to be duplicated until temporary instance of Fluent Bit is deleted
  after the upgrade is complete. As temporary instance of Fluent Bit creates additional Pods
  which are selected by the same Fluent Bit Service you may observe changes in Fluent Bit metrics.

  Copy of database, in which Fluent Bit keeps track of monitored files and offsets, is used by temporary instance of Fluent Bit
  (Fluent Bit database is copied in initContainer).
  Temporary instance of Fluent Bit will start reading logs with offsets saved in database.

  To create a temporary copy of Fluent Bit DaemonSet:

  ```bash
  INIT_CONTAINER=$(cat <<-"EOF"
    name: init-tmp-fluent-bit
    image: busybox:latest
    command: ['sh', '-c', 'mkdir -p /tail-db/tmp; cp /tail-db/*.db /tail-db/tmp']
    volumeMounts:
      - mountPath: /tail-db
        name: tail-db
  EOF
  ) && \
  TMP_VOLUME=$(cat <<-"EOF"
      hostPath:
          path: /var/lib/fluent-bit/tmp
          type: DirectoryOrCreate
      name: tmp-tail-db
  EOF
  ) && \
  kubectl get daemonset --namespace <NAMESPACE-NAME> --selector "app=fluent-bit,release=<RELEASE-NAME>" --output yaml | \
  yq w - "items[*].metadata.name" "tmp-fluent-bit" | \
  yq w - "items[*].metadata.labels[heritage]" "tmp" | \
  yq w - "items[*].spec.template.metadata.labels[app.kubernetes.io/name]" "fluent-bit" | \
  yq w - "items[*].spec.template.metadata.labels[app.kubernetes.io/instance]" "<RELEASE-NAME>" | \
  yq w - "items[*].spec.template.spec.initContainers[+]" --from <(echo "${INIT_CONTAINER}") | \
  yq w - "items[*].spec.template.spec.volumes[+]" --from <(echo "${TMP_VOLUME}") | \
  yq w - "items[*].spec.template.spec.containers[*].volumeMounts[*].(.==tail-db)" "tmp-tail-db" | \
  kubectl create --filename -
  ```

  Please make sure that Pods related to new DaemonSet are running:

  ```bash
  kubectl get pod --namespace <NAMESPACE-NAME> --selector "app=fluent-bit,release=<RELEASE-NAME>,app.kubernetes.io/name=fluent-bit,app.kubernetes.io/instance=<RELEASE-NAME>"
  ```

  Please check that the latest logs are duplicated in Sumo.

  To delete Fluent Bit DaemonSet with old version of `spec.selector`:

  ```bash
  kubectl delete daemonset --namespace <NAMESPACE-NAME> --selector "app=fluent-bit,heritage=Helm,release=<RELEASE-NAME>"
  ```

  **Notice:** When collection upgrade creates new DaemonSet for Fluent Bit,
  logs will be duplicated.
  In order to stop data duplication it is required to remove the temporary copy
  of Fluent Bit DaemonSet after the upgrade has finished.

  After collection upgrade is done, in order to remove the temporary Fluent Bit
  DaemonSet run the following commands:

   ```bash
  kubectl wait --for=condition=ready pod \
    --namespace <NAMESPACE-NAME> \
    --selector "app.kubernetes.io/name=fluent-bit,app.kubernetes.io/instance=<RELEASE-NAME>,app!=fluent-bit,release!=<RELEASE-NAME>" && \
  kubectl delete daemonset \
    --namespace <NAMESPACE-NAME> \
    --selector "app=fluent-bit,release=<RELEASE-NAME>,heritage=tmp"
  ```

### 4. Run upgrade script

For Helm users, the only breaking changes are the renamed config parameters.
For users who use a `values.yaml` file, we provide a script that users can run
to convert their existing `values.yaml` file into one that is compatible with the major release.

- Get the existing values for the helm chart and store it as `current_values.yaml`
  with the below command:

  ```bash
  helm get values --output yaml <RELEASE-NAME> > current_values.yaml
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
