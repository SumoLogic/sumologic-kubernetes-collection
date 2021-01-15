# Kubernetes Collection `v2.0.0` - Breaking Changes

- [Helm Users](#helm-users)
  - [Changes](#changes)
  - [How to upgrade](#how-to-upgrade)
    - [Requirements](#requirements)
    - [1. Upgrade to helm chart version `v1.3.5`](#1-upgrade-to-helm-chart-version-v135)
      - [Ensure you have sumologic helm repo added](#ensure-you-have-sumologic-helm-repo-added)
      - [Update](#update)
    - [2. Upgrade Prometheus CRDs](#2-upgrade-prometheus-crds)
    - [3. Prepare Fluent Bit instance](#3-prepare-fluent-bit-instance)
      - [Recreating Fluent Bit DaemonSet](#recreating-fluent-bit-daemonset)
      - [Preparing temporary instance of Fluent Bit](#preparing-temporary-instance-of-fluent-bit)
    - [4. Configure Fluentd persistence](#4-configure-fluentd-persistence)
    - [5. Run upgrade script](#5-run-upgrade-script)
- [Non-Helm Users](#non-helm-users)
  - [Breaking Changes](#breaking-changes)
  - [How to upgrade for Non-helm Users](#how-to-upgrade-for-non-helm-users)
    - [1. Tear down existing Fluentd, Prometheus, Fluent Bit and Falco resources](#1-tear-down-existing-fluentd-prometheus-fluent-bit-and-falco-resources)
    - [2. Deploy collection with new approach](#2-deploy-collection-with-new-approach)

Based on the feedback from our users, we will be introducing several changes
to the Sumo Logic Kubernetes Collection solution.

In this document we detail the changes for both Helm and Non-Helm users,
as well as the exact steps for migration.

## Helm Users

### Changes

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

- Persistence for Fluentd is enabled by default.

### How to upgrade

#### Requirements

- `helm3`
- `yq` in version: `3.4.0` <= `x` < `4.0.0`
- `bash` 4.0 or higher

**Note: The below steps are using Helm 3. Helm 2 is not supported.**

#### 1. Upgrade to helm chart version `v1.3.5`

If you're running a newer version than `v1.3.5`, instructions from this document
will also work for you.

##### Ensure you have sumologic helm repo added

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

##### Update

Run the command shown below to fetch the latest helm chart:

```bash
helm repo update
```

For users who are not already on `v1.3.5` of the helm chart, please upgrade
to that version first by running the below command:

```bash
helm upgrade <RELEASE-NAME> sumologic/sumologic --reuse-values --version=1.3.5
```

#### 2. Upgrade Prometheus CRDs

Due to changes in `kube-prometheus-stack` which this chart depends on, one will
need to run the following commands in order to update Prometheus related CRDs:

```bash
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.43.2/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
```

If you have a separate Prometheus operator installation, you need to make sure its version
is [v0.43.2](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.43.2)
or higher but compatible before proceeding with the next steps of the collection upgrade.

#### 3. Prepare Fluent Bit instance

As `spec.selector` in Fluent Bit Helm chart was modified, it is required to manually recreate
or delete existing DaemonSet with old version of `spec.selector` before upgrade.

One of the following two strategies can be used:

- ##### Recreating Fluent Bit DaemonSet

  Recreating Fluent Bit DaemonSet with new `spec.selector` may cause that
  applications' logs and Fluent Bit metrics will not be available in the time of recreation.
  It usually shouldn't take more than several seconds.

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

  **Notice**  When DaemonSet managed by helm is modified by the command specified above,
  one might expect a warning similar to the one below:
  `Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply`

- ##### Preparing temporary instance of Fluent Bit

  Create temporary instance of Fluent Bit and delete DaemonSet with old version of `spec.selector`.
  This will cause application' logs to be duplicated until temporary instance of Fluent Bit is deleted
  after the upgrade is complete. As temporary instance of Fluent Bit creates additional Pods
  which are selected by the same Fluent Bit Service you may observe changes in Fluent Bit metrics.

  Copy of database, in which Fluent Bit keeps track of monitored files and offsets,
  is used by temporary instance of Fluent Bit (Fluent Bit database is copied in initContainer).
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
  kubectl get pod \
    --namespace <NAMESPACE-NAME> \
    --selector "app=fluent-bit,release=<RELEASE-NAME>,app.kubernetes.io/name=fluent-bit,app.kubernetes.io/instance=<RELEASE-NAME>"
  ```

  Please check that the latest logs are duplicated in Sumo.

  To delete Fluent Bit DaemonSet with old version of `spec.selector`:

  ```bash
  kubectl delete daemonset \
    --namespace <NAMESPACE-NAME> \
    --selector "app=fluent-bit,heritage=Helm,release=<RELEASE-NAME>"
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

#### 4. Configure Fluentd persistence

Starting with `v2.0.0` we're using file-based buffer for Fluentd instead of less
reliable in-memory buffer (`fluentd.persistence.enabled=true`) by default.

When Fluentd persistence is enabled then no action is required in order to upgrade.

When Fluentd persistence is disabled (default setting in `1.3.5` release)
it is required to either go through persistence enabling procedure before upgrade (recommended)
or preserve existing setting and modify default setting for Fluentd persistence in `2.0.0` release.

**In order to enable persistence in existing collection** please follow one
of persistence enabling procedures described in
[Enabling Fluentd Persistence guide](FluentdPersistence.md#enabling-fluentd-persistence)
before upgrade.

If Fluentd persistence is disabled and it is desired to preserve this setting,
modify defaults and disable persistence either by adding `--set fluentd.persistence.enabled=false`
to `helm upgrade` command or in the `values.yaml` file under the `fluentd` key as follows:

```yaml
fluentd:
  persistence:
    enabled: false
```

#### 5. Run upgrade script

For Helm users, the only breaking changes are the renamed config parameters.
For users who use a `values.yaml` file, we provide a script that users can run
to convert their existing `values.yaml` file into one that is compatible with the major release.

- Get the existing values for the helm chart and store it as `current_values.yaml`
  with the below command:

  ```bash
  helm get values --output yaml <RELEASE-NAME> > current_values.yaml
  ```

- Run the upgrade script. You can run it:

  - On your the host. Please refer to the [requirements](#requirements) so that you have
    all the required software packages installed.

    ```bash
    curl -LJO https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/release-v2.0/deploy/helm/sumologic/upgrade-2.0.0.sh \
    && chmod +x upgrade-2.0.0.sh \
    && ./upgrade-2.0.0.sh current_values.yaml
    ```

  - In a docker container:

    ```bash
    cat current_values.yaml | \
      docker run \
        --rm \
        -i sumologic/kubernetes-tools:2.3.0 upgrade-2.0 | \
      tee new_values.yaml
    ```

    Note that this will output both migration script logs and new values file but
    only the values file contents will be put into `new_values.yaml` due to `tee`.

  - In a container on your cluster:

    ```bash
    cat current_values.yaml | \
      kubectl run kubernetes-tools -i \
        --quiet \
        --rm \
        --restart=Never \
        --image sumologic/kubernetes-tools:2.3.0 -- upgrade-2.0 | \
      tee new_values.yaml
    ```

    Note that this will output both migration script logs and new values file but
    only the values file contents will be put into `new_values.yaml` due to `tee`.

- At this point you should have `new_values.yaml` in your working directory which
  can be used for the upgrade:

  ```bash
  helm upgrade <RELEASE-NAME> sumologic/sumologic --version=2.0.0 -f new_values.yaml
  ```

## Non-Helm Users

### Breaking Changes

- From `v2.0.0` we recommend to use helm3 template as replacement for pre-generated
  kubernetes templates.
  Because of that, all custom changes made to the templates should be moved to `values.yaml`.
  This will simplify and improve experience for non-helm installation.

### How to upgrade for Non-helm Users

#### 1. Tear down existing Fluentd, Prometheus, Fluent Bit and Falco resources

You will need the YAML files you created when you first installed collection.
Run the following commands to remove Falco, Fluent-bit, Prometheus Operator and FluentD.
You do not need to delete the Namespace and Secret you originally created as they will still be used.

```sh
kubectl delete -f falco.yaml
kubectl delete -f fluent-bit.yaml
kubectl delete -f prometheus.yaml
kubectl delete -f fluentd-sumologic.yaml
```

#### 2. Deploy collection with new approach

- Follow steps mentioned [here][non_helm_installation_customizing_installation]
  to deploy new collection.

[non_helm_installation_customizing_installation]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2.0/deploy/docs/Non_Helm_Installation.md#customizing-installation
