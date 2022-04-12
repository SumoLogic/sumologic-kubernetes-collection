# Fluentd persistence

Starting with `v2.0.0` we're using file-based buffer for Fluentd instead of less
reliable in-memory buffer by default.

The buffer configuration can be set in the `values.yaml` file under the `fluentd`
key as follows:

```yaml
fluentd:
  persistence:
    enabled: true
```

When the Fluentd persistence setting is to be changed (enabled or disabled)
it is required to recreate or delete existing Fluentd StatefulSet,
as it is not possible to add/remove `volumeClaimTemplate` for StatefulSet.

**Note:** The below commands are using `yq` in version `3.4.0` <= `x` < `4.0.0`.

## Enabling Fluentd persistence

To enable the Fluentd persistence modify `values.yaml` file under the `fluentd` key as follows:

```yaml
fluentd:
  persistence:
    enabled: true
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner (gp2 on AWS, standard on
    ##   GKE, Azure & OpenStack)
    ##
    # storageClass: "-"
    # annotations: {}
    accessMode: ReadWriteOnce
    size: 10Gi
  buffer:
    totalLimitSize: "10G"
```

Keep in mind that you need to adjust `fluentd.buffer.totalLimitSize` in order for FluentD to actually queue
more data - increasing volume size alone is not enough.

Use one of following two strategies to prepare existing collection for enabling Fluentd persistence:

- ### Enabling Fluentd persistence by recreating Fluentd StatefulSet

  In a heavy used clusters with high load of logs and metrics it might be possible that
  recreating Fluentd StatefulSet with new `volumeClaimTemplate` may cause logs and metrics
  being unavailable for the time of recreation. It usually shouldn't take more than several seconds.

  To recreate Fluentd StatefulSets with new `volumeClaimTemplate` one can run
  the following commands for all Fluentd StatefulSets.

  Remember to adjust `volumeClaimTemplate` (`VOLUME_CLAIM_TEMPLATE` variable in command below)
  which will be added to `volumeClaimTemplates` in StatefulSet `spec` according to your needs,
  for details please check `PersistentVolumeClaim` in Kubernetes API specification.

  Also remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  VOLUME_CLAIM_TEMPLATE=$(cat <<-"EOF"
  metadata:
    name: buffer
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
  EOF
  ) && \
  BUFFER_VOLUME=$(cat <<-"EOF"
  mountPath: /fluentd/buffer
  name: buffer
  EOF
  )&& \
  kubectl --namespace ${NAMESPACE} get statefulset ${RELEASE_NAME}-sumologic-fluentd-logs --output yaml | \
  yq w - "spec.volumeClaimTemplates[+]" --from <(echo "${VOLUME_CLAIM_TEMPLATE}") | \
  yq w - "spec.template.spec.containers[0].volumeMounts[+]" --from <(echo "${BUFFER_VOLUME}") | \
  kubectl apply --namespace ${NAMESPACE} --force --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  VOLUME_CLAIM_TEMPLATE=$(cat <<-"EOF"
  metadata:
    name: buffer
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
  EOF
  ) && \
  BUFFER_VOLUME=$(cat <<-"EOF"
  mountPath: /fluentd/buffer
  name: buffer
  EOF
  )&& \
  kubectl --namespace ${NAMESPACE} get statefulset ${RELEASE_NAME}-sumologic-fluentd-metrics --output yaml | \
  yq w - "spec.volumeClaimTemplates[+]" --from <(echo "${VOLUME_CLAIM_TEMPLATE}") | \
  yq w - "spec.template.spec.containers[0].volumeMounts[+]" --from <(echo "${BUFFER_VOLUME}") | \
  kubectl apply --namespace ${NAMESPACE} --force --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  VOLUME_CLAIM_TEMPLATE=$(cat <<-"EOF"
  metadata:
    name: buffer
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
  EOF
  ) && \
  BUFFER_VOLUME=$(cat <<-"EOF"
  mountPath: /fluentd/buffer
  name: buffer
  EOF
  )&& \
  kubectl --namespace ${NAMESPACE} get statefulset ${RELEASE_NAME}-sumologic-fluentd-events --output yaml | \
  yq w - "spec.volumeClaimTemplates[+]" --from <(echo "${VOLUME_CLAIM_TEMPLATE}") | \
  yq w - "spec.template.spec.containers[0].volumeMounts[+]" --from <(echo "${BUFFER_VOLUME}") | \
  kubectl apply --namespace ${NAMESPACE} --force --filename -
  ```

  **Notice** When StatefulSets managed by helm are modified by commands specified above,
  one might expect a warning similar to this one:
   `Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply`

  Upgrade collection with Fluentd persistence enabled, e.g.

  ```bash
  helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
  ```

- ### Enabling Fluentd persistence by preparing temporary instances of Fluentd and removing earlier created

  To create a temporary instances of Fluentd StatefulSets and avoid a loss of logs or metrics one can run the following commands.

  Remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl get statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-logs --output yaml | \
  yq w - "metadata.name" tmp-${RELEASE_NAME}-sumologic-fluentd-logs | \
  yq w - "metadata.labels[heritage]" "tmp" | \
  yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
  yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
  kubectl create --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl get statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-metrics --output yaml | \
  yq w - "metadata.name" tmp-${RELEASE_NAME}-sumologic-fluentd-metrics | \
  yq w - "metadata.labels[heritage]" "tmp" | \
  yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
  yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
  kubectl create --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl get statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-events --output yaml | \
  yq w - "metadata.name" tmp-${RELEASE_NAME}-sumologic-fluentd-events | \
  yq w - "metadata.labels[heritage]" "tmp" | \
  yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
  yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
  kubectl create --filename -
  ```

  Delete old instances of Fluentd StatefulSets:

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl wait --for=condition=ready pod \
    --namespace ${NAMESPACE} \
    --selector "release==${RELEASE_NAME},heritage=tmp" && \
  kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-events && \
  kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-logs && \
  kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-metrics
  ```

  Upgrade collection with Fluentd persistence enabled, e.g.

  ```bash
  helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
  ```

  **Notice:** After the Helm chart upgrade is done, in order to remove temporary Fluentd
  StatefulSets run the following command:

   ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl wait --for=condition=ready pod \
    --namespace ${NAMESPACE} \
    --selector "release==${RELEASE_NAME},heritage=Helm" && \
  kubectl delete statefulset \
    --namespace ${NAMESPACE} \
    --selector "release==${RELEASE_NAME},heritage=tmp"
  ```

## Disabling Fluentd persistence

To disable Fluentd persistence in existing collection modify `values.yaml` file under the `fluentd`
key as follows:

```yaml
fluentd:
  persistence:
    enabled: false
```

Use one of following two strategies to prepare existing collection for disabling Fluentd persistence:

- ### Disabling Fluentd persistence by recreating Fluentd StatefulSet

  In a heavy used clusters with high load of logs and metrics it might be possible that
  recreating Fluentd StatefulSet without `volumeClaimTemplate` may cause logs and metrics
  being unavailable for the time of recreation. It usually shouldn't take more than several seconds.

  To recreate Fluentd StatefulSets without `volumeClaimTemplate` one can run
  the following commands for all Fluentd StatefulSets.

  Remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl --namespace ${NAMESPACE} get statefulset ${RELEASE_NAME}-sumologic-fluentd-logs --output yaml | \
  yq d - "spec.template.spec.containers[*].volumeMounts(name==buffer)" | \
  yq d - "spec.volumeClaimTemplates(metadata.name==buffer)" | \
  kubectl apply --namespace ${NAMESPACE} --force --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl --namespace ${NAMESPACE} get statefulset ${RELEASE_NAME}-sumologic-fluentd-metrics --output yaml | \
  yq d - "spec.template.spec.containers[*].volumeMounts(name==buffer)" | \
  yq d - "spec.volumeClaimTemplates(metadata.name==buffer)" | \
  kubectl apply --namespace ${NAMESPACE} --force --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl --namespace ${NAMESPACE} get statefulset ${RELEASE_NAME}-sumologic-fluentd-events --output yaml | \
  yq d - "spec.template.spec.containers[*].volumeMounts(name==buffer)" | \
  yq d - "spec.volumeClaimTemplates(metadata.name==buffer)" | \
  kubectl apply --namespace ${NAMESPACE} --force --filename -
  ```

  **Notice** When StatefulSets managed by helm are modified by commands specified above,
  one might expect a warning similar to this one:
  `Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply`

  Upgrade collection with Fluentd persistence disabled, e.g.

  ```bash
  helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
  ```

  **Notice:** After the Helm chart upgrade is done, it is needed to remove remaining `PersistentVolumeClaims`
  which are no longer used by Fluend Statefulsets.

  To remove remaining `PersistentVolumeClaims`:

  ```bash
  kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-fluentd-logs
  kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-fluentd-metrics
  kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-fluentd-events
  ```

- ### Disabling Fluentd persistence by preparing temporary instances of Fluentd and removing earlier created

  To create a temporary instances of Fluentd StatefulSets and avoid a loss of logs or metrics one can run the following commands.

  Remember to replace the `NAMESPACE` and `RELEASE_NAME` variables with proper values.

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl get statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-logs --output yaml | \
  yq w - "metadata.name" tmp-${RELEASE_NAME}-sumologic-fluentd-logs | \
  yq w - "metadata.labels[heritage]" "tmp" | \
  yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
  yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
  kubectl create --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl get statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-metrics --output yaml | \
  yq w - "metadata.name" tmp-${RELEASE_NAME}-sumologic-fluentd-metrics | \
  yq w - "metadata.labels[heritage]" "tmp" | \
  yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
  yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
  kubectl create --filename -
  ```

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl get statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-events --output yaml | \
  yq w - "metadata.name" tmp-${RELEASE_NAME}-sumologic-fluentd-events | \
  yq w - "metadata.labels[heritage]" "tmp" | \
  yq w - "spec.template.metadata.labels[heritage]" "tmp" | \
  yq w - "spec.selector.matchLabels[heritage]" "tmp" | \
  kubectl create --filename -
  ```

  Delete old instances of Fluentd StatefulSets:

  ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl wait --for=condition=ready pod \
    --namespace ${NAMESPACE} \
    --selector "release==${RELEASE_NAME},heritage=tmp" && \
  kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-events && \
  kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-logs && \
  kubectl delete statefulset --namespace ${NAMESPACE} ${RELEASE_NAME}-sumologic-fluentd-metrics
  ```

  Upgrade collection with Fluentd persistence disabled, e.g.

  ```bash
  helm upgrade <RELEASE-NAME> sumologic/sumologic --version=<VERSION> -f <VALUES>
  ```

  **Notice:** After the Helm chart upgrade is done, it is needed to remove temporary Fluentd
  StatefulSets and remaining `PersistentVolumeClaims` which are no longer used by Fluend Statefulsets.

  To remove temporary Fluentd StatefulSets:

   ```bash
  NAMESPACE=sumologic && \
  RELEASE_NAME=collection && \
  kubectl wait --for=condition=ready pod \
    --namespace ${NAMESPACE} \
    --selector "release==${RELEASE_NAME},heritage=Helm" && \
  kubectl delete statefulset \
    --namespace ${NAMESPACE} \
    --selector "release==${RELEASE_NAME},heritage=tmp"
  ```

  To remove remaining `PersistentVolumeClaims`:

  ```bash
  kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-fluentd-logs
  kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-fluentd-metrics
  kubectl delete pvc --namespace ${NAMESPACE} --selector app=${RELEASE_NAME}-sumologic-fluentd-events
  ```
