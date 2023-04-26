# Troubleshooting Collection

<!-- TOC -->

- [`helm install` hanging](#helm-install-hanging)
- [Installation fails with error `function "dig" not defined`](#installation-fails-with-error-function-dig-not-defined)
- [Namespace configuration](#namespace-configuration)
- [Collecting logs](#collecting-logs)
  - [Check Fluentd autoscaling](#check-fluentd-autoscaling)
  - [Fluentd Logs](#fluentd-logs)
  - [Send data to Fluentd stdout instead of to Sumo](#send-data-to-fluentd-stdout-instead-of-to-sumo)
  - [Send data to Fluent Bit stdout](#send-data-to-fluent-bit-stdout)
- [Collecting metrics](#collecting-metrics)
  - [Check Fluentd autoscaling](#check-fluentd-autoscaling-1)
  - [Check FluentBit and Fluentd output metrics](#check-fluentbit-and-fluentd-output-metrics)
- [Common Issues](#common-issues)
  - [Fluentd Pod stuck in `Pending` state after recreation](#fluentd-pod-stuck-in-pending-state-after-recreation)
  - [Gzip compression errors](#gzip-compression-errors)
  - [`/fluentd/buffer` permissions issue](#fluentdbuffer-permissions-issue)
  - [Duplicated logs](#duplicated-logs)
  - [Multiline log detection doesn't work as expected](#multiline-log-detection-doesnt-work-as-expected)
    - [Using text format](#using-text-format)

<!-- /TOC -->

## `helm install` hanging

If `helm install` hangs, it usually means the pre-install setup job is failing and is in a retry loop. Due to a Helm limitation, errors from
the setup job cannot be fed back to the `helm install` command. Kubernetes schedules the job in a pod, so you can look at logs from the pod
to see why the job is failing. First find the pod name in the namespace where the Helm chart is deployed:

```sh
kubectl get pods -n sumologic
```

Get the logs from that pod:

```
kubectl logs POD_NAME -f
```

If you see `Secret 'sumologic::sumologic' exists, abort.` from the logs, delete the existing secret:

```
kubectl delete secret sumologic -n sumologic
```

`helm install` should proceed after the existing secret is deleted before exhausting retries. If it did time out after exhausting retries,
rerun the `helm install` command.

## Installation fails with error `function "dig" not defined`

You need to use a more recent version of Helm. See [Minimum Requirements](/docs/README.md#minimum-requirements).

If you are using ArgoCD or another tool that uses Helm under the hood, make sure that tool uses the required version of Helm.

## Namespace configuration

The following `kubectl` commands assume you are in the correct namespace `sumologic`. By default, these commands will use the namespace
`default`.

To run a single command in the `sumologic` namespace, pass in the flag `-n sumologic`.

To set your namespace context more permanently, you can run

```sh
kubectl config set-context $(kubectl config current-context) --namespace=sumologic
```

## Collecting logs

If you cannot see logs in Sumo that you expect to be there, here are the things to check.

### Check Fluentd autoscaling

Check if Fluentd autoscaling is enabled, for details please see [Fluentd Autoscaling][fluend_autoscaling] documentation.

Some known indicators that autoscaling for Fluentd must be enabled:

- High CPU usage for Fluentd Pods (above `500m`), resource consumption can be checked using `kubectl top pod -n <NAMESPACE>`

- Following message in Fluentd logs: `failed to write data into buffer by buffer overflow action=:drop_oldest_chunk`

[fluend_autoscaling]: /docs/best-practices.md#fluentd-autoscaling

### Fluentd Logs

```
kubectl logs collection-sumologic-xxxxxxxxx-xxxxx -f
```

To enable more detailed debug or trace logs from all of Fluentd, add the following lines to the `fluentd-sumologic.yaml` file under the
relevant `.conf` section and apply the change to your deployment:

```
<system>
  log_level debug # or trace
</system>
```

To enable debug or trace logs from a specific Fluentd plugin, add the following option to the plugin's `.conf` section:

```
<match **>
  @type sumologic
  @log_level debug # or trace
  ...
</match>
```

To enable debug or trace logs using the Helm chart, you can override the value `fluentd.logLevel` in `user-values.yaml`:

```yaml
fluentd:
  logLevel: debug
```

```sh
helm upgrade collection sumologic/sumologic -f user-values.yaml
```

For configuration changes to take effect in Fluentd, you can redeploy the pods by scaling to zero and back to the desired deployment size:

```sh
kubectl scale deployment/collection-sumologic --replicas=0
kubectl scale deployment/collection-sumologic --replicas=3
```

Where `collection` is the `helm` release name.

### Send data to Fluentd stdout instead of to Sumo

To help reduce the points of possible failure, we can write data to Fluentd logs rather than sending to Sumo directly using the Sumo Logic
output plugin. To do this, use the following configuration:

```yaml
fluentd:
  logs:
    containers:
      extraFilterPluginConf: |-
        # Prevent fluentd from processing they own logs
        <match **fluentd**>
          @type null
        </match>
        # Print all container logs before any filter applied
        <filter **>
          @type stdout
        </filter>
      extraOutputPluginConf: |-
        # Print all container logs just before sending them to Sumo
        <filter **>
          @type stdout
        </filter>
```

You should see data being sent to Fluentd logs, which you can get using the commands [above](#fluentd-logs).

### Send data to Fluent Bit stdout

In order to see what exactly the Fluent Bit reads, you can write data to Fluent Bit logs. To do this, use the following configuration:

```yaml
fluent-bit:
  config:
    filters: |
      # Prevent fluent-bit and fluentd logs from further processing
      [FILTER]:
          Name grep
          Match *fluent*
          Exclude log ^
      # Print logs
      [FILTER]
          Name stdout
          Match *
```

## Collecting metrics

### Check Fluentd autoscaling

Check if Fluentd autoscaling is enabled, for details please see [Fluentd Autoscaling][fluend_autoscaling] documentation.

Some known indicators that autoscaling for Fluentd must be enabled:

- High CPU usage for Fluentd Pods (above `500m`), resource consumption can be checked using `kubectl top pod -n <NAMESPACE>`

- Following message in Fluentd logs: `failed to write data into buffer by buffer overflow action=:drop_oldest_chunk`

### Check FluentBit and Fluentd output metrics

By default, we collect input/output plugin metrics for FluentBit, and output metrics for Fluentd that you can use to verify collection:

Relevant FluentBit metrics include:

- fluentbit_input_bytes_total
- fluentbit_input_records_total
- fluentbit_output_proc_bytes_total
- fluentbit_output_proc_records_total
- fluentbit_output_retries_total
- fluentbit_output_retries_failed_total

Relevant Fluentd metrics include:

- fluentd_output_status_emit_records
- fluentd_output_status_buffer_queue_length
- fluentd_output_status_buffervqueuevbytes
- fluentd_output_status_num_errors
- fluentd_output_status_retry_count

## Common Issues

### Fluentd Pod stuck in `Pending` state after recreation

If you are seeing a Fluentd Pod stuck in the `Pending` state, using the [file based buffering](best-practices.md#fluentd-file-based-buffer)
(default since v2.0) and seeing logs like

```
Warning  FailedScheduling  16s (x23 over 31m)  default-scheduler  0/6 nodes are available: 2 node(s) had volume node affinity conflict, 4 node(s) were unschedulable.
```

you have a volume node affinity conflict. It can happen when Fluentd Pod was running in one AZ and has been rescheduled into another AZ.
Deleting the existing PVC and then killing the Pod should resolve this issue.

The Fluentd StatefulSet Pods and their PVCs are bound by their number: `*-sumologic-fluentd-logs-1` Pod will be using the
`buffer-*-sumologic-fluentd-logs-1` PVC.

### Gzip compression errors

If you observe the following errors from Fluentd pods:

```console
2021-01-18 15:47:23 +0000 [warn]: #0 [sumologic.endpoint.logs.gc] failed to flush the buffer. retry_time=3 next_retry_seconds=2021-01-18 15:47:27 +0000 chunk="5b92e97a5ee3cbd7e59859644d9686e3" error_class=Zlib::GzipFile::Error error="not in gzip format"
```

Please disable gzip compression for buffer. Add following configuration to your `user-values.yaml` and upgrade collection:

```yaml
fluentd:
  buffer:
    compress: text
```

After that, please remove Fluentd pods and associated PVC-s.

For example, if the namespace where the collection is installed is `collection`, run the following set of commands:

```bash
NAMESPACE_NAME=collection

for POD_NAME in $(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep fluentd); do
  kubectl -n ${NAMESPACE_NAME} delete pvc "buffer-${POD_NAME}" &
  kubectl -n ${NAMESPACE_NAME} delete pod ${POD_NAME}
  kubectl -n ${NAMESPACE_NAME} delete pod ${POD_NAME}
done
```

The duplicated pod deletion command is there to make sure the pod is not stuck in `Pending` state with event
`persistentvolumeclaim "buffer-sumologic-fluentd-logs-1" not found`.

### `/fluentd/buffer` permissions issue

When you encounter the following (or a similar) error message in fluentd logs:

```
2021-11-23 07:05:56 +0000 [error]: #0 unexpected error error_class=Errno::EACCES error="Permission denied @ dir_s_mkdir - /fluentd/buffer/logs"
```

this means that most likely the volume that has been provisioned as PersistentVolume for your fluentd has incorrect ownership and/or
permissions set.

You can verify that this is the case with the following `kubectl` command:

```
$ kubectl exec -it -n <NAMESPACE> <RELEASE_NAME>-<NAMESPACE>-fluentd-logs-0 \
  --container fluentd -- ls -ld /fluentd/buffer
drwx------ 6 root root 4096 Dec 17 16:01 /fluentd/buffer
```

In the above snippet you can observe that `/fluentd/buffer/` is owned by `root`, and only that user can access it.

There are many possible reasons for this behaviour, this can depend on the cloud provider that you use and the StorageClasses that are
available/set in your cluster.

We have a couple of possible solutions for this issue:

1. Use an init container that will `chown` the buffer directory. Init containers for fluentd are available since collection chart version
   [`v2.3.0`][v2_3] and can be utilized in the following manner:

```yaml
fluentd:
  logs:
    enabled: true
    statefulset:
      initContainers:
        - name: chown
          image: busybox:latest
          # Please note that the user that our fluentd instances run as has an ID of 999
          # and a primary group 999
          # rel: https://github.com/SumoLogic/sumologic-kubernetes-fluentd/blob/b8b51/Dockerfile#L113
          command: ["chown", "-R", "999:999", "/fluentd/buffer"]
          volumeMounts:
            - name: buffer
              mountPath: "/fluentd/buffer"
```

1. Use a [security context][security_context] that will make your fluentd run as a different user. Mark that below snippet will run fluentd
   as `root` which in security constrained environments might not be desired.

```yaml
fluentd:
  logs:
    enabled: true
    statefulset:
      containers:
        fluentd:
          securityContext:
            runAsUser: 0
```

1. Use a different [storage class][storage_class]:

```
fluentd:
  persistence:
    storageClass: managed-csi
```

[v2_3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases/tag/v2.3.0
[storage_class]: https://kubernetes.io/docs/concepts/storage/storage-classes/
[security_context]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

### Duplicated logs

We observed than under certain conditions, it's possible for Fluentd to duplicate logs:

- there are several requests made of one chunk
- one of those requests is failing, resulting in the whole batch being retried

In order to mitigate this, please use [fluentd-output-sumologic] with `use_internal_retry` option. Please follow
[Split Big Chunks in Fluentd](best-practices.md#split-big-chunks-in-fluentd)

[fluentd-output-sumologic]: https://github.com/SumoLogic/fluentd-output-sumologic

### Multiline log detection doesn't work as expected

In order to detect multiline logs, we relay on regexes. By default we use the following regex to detect multiline:

- `\[?\d{4}-\d{1,2}-\d{1,2}.\d{2}:\d{2}:\d{2}.*`

  Which matches the following example logs:

  ```text
  [2022-06-28 00:00:00 ...
  [2022-06-28T00:00:00 ...
  2022-06-28 00:00:00 ...
  2022-06-28T00:00:00 ...
  ```

This regex should cover most of the cases, but as log formats are not unified, it doesn't cover all multiline logs.

Consider the following examples:

- Text format is used for sending data to sumo

#### Using text format

##### Problem

If you changed log format to `text`, you need to know that multiline detection performed on the collection side is not respected anymore. As
we are sending logs as a wall of plain text, there is no way to inform Sumo Logic, which line belongs to which log. In such scenario,
multiline detection is performed on Sumo Logic side. By default it uses [Infer Boundaries][infer-boundaries]. You can review the source
configuration in [HTTP Source Settings][http-source].

**Note**: Your source name is going to be taken from `sumologic.collectorName` or `sumologic.clusterName` (`kubernetes` by default).

##### Resolution

In order to change multiline detection to [Boundary Regex][boundary-regex], for example to `\[?\d{4}-\d{1,2}-\d{1,2}.\d{2}:\d{2}:\d{2}.*`,
add the following configuration to your `user-values.yaml`:

```yaml
sumologic:
  collector:
    sources:
      logs:
        default:
          properties:
            ## Disable automatic multiline detection on collector side
            use_autoline_matching: false
            ## Set the following multiline detection regexes on collector side:
            ## - \{".* - in order to match json lines
            ## - \[?\d{4}-\d{1,2}-\d{1,2}.\d{2}:\d{2}:\d{2}.*
            ## Note: `\` is translated to `\\` and `"` to `\"` as we pass to terraform script
            manual_prefix_regexp: (\\{\".*|\\[?\\d{4}-\\d{1,2}-\\d{1,2}.\\d{2}:\\d{2}:\\d{2}.*)
```

**Note**: Double escape of `\` is needed, as well as escaping `"`, because value of `manual_prefix_regexp` is passed to terraform script.

**Note**: If you use `json` format along with `text` format, you need to add regex for `json` as well (`\\{\".*`)

**Note**: Details about `sumologic.collector.sources` configuration can be found [here][sumologic-terraform-provider]

[infer-boundaries]: https://help.sumologic.com/docs/send-data/reference-information/collect-multiline-logs#infer-boundaries
[http-source]: https://help.sumologic.com/docs/send-data/hosted-collectors/http-source
[boundary-regex]: https://help.sumologic.com/docs/send-data/reference-information/collect-multiline-logs#boundary-regex
[sumologic-terraform-provider]: ../terraform.md#sumo-logic-terraform-provider
