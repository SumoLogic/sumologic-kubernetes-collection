# Advanced Configuration / Best Practices

- [Topics](#advanced-configuration---best-practices)
    + [Multiline Log Support](#multiline-log-support)
    + [Log lines over 16KB are truncated](#log-lines-over-16kb-are-truncated)
    + [Fluentd autoscaling:](#fluentd-autoscaling-)
    + [Fluentd File-based buffer](#fluentd-file-based-buffer)
    + [Excluding Logs From Specific Components](#excluding-logs-from-specific-components)
    + [Add a local file to fluent-bit configuration](#add-a-local-file-to-fluent-bit-configuration)
    + [Filtering Prometheus Metrics by Namespace in the Remote Write Config](#filtering-prometheus-metrics-by-namespace-in-the-remote-write-config)
    + [Send Data to AWS S3](#send-data-to-aws-s3)

### Multiline Log Support

By default, we use a regex that matches the first line of multiline logs that start with dates in the following format: `2019-11-17 07:14:12`.

If your logs have a different date format you can provide a custom regex to detect the first line of multiline logs. See [collecting multiline logs](https://help.sumologic.com/?cid=49494) for details on configuring a boundary regex.

New parsers can be defined under the `parsers` key of the fluent-bit configuration section in the `values.yaml` file as follows:

```
parsers:
  enabled: true
  regex:
    - name: multi_line
    regex: (?<log>^{"log":"\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}:\d{2}.*)
    - name: new_parser_name
    ## This parser matches lines that start with time of the format : 07:14:12
    regex: (?<log>^{"log":"\d{2}:\d{2}:\d{2}.*)
```

The regex used for `Parser_Firstline` needs to have at least one named capture group.

To use the newly defined parser to detect the first line of multiline logs, change the `Parser_Firstline` parameter in the `Input plugin` configuration of fluent-bit:

```bash
Parser_Firstline new_parser_name
```

You can also use the optional-extra parser to interpret and structure multiline entries.
When Multiline is On, if the first line matches `Parser_Firstline`, the rest of the lines will be matched against `Parser_N`.

```bash
Parser_Firstline multi_line
Parser_1 optional_parser
```
### Log lines over 16KB are truncated
Docker daemon has a limit of 16KB/line so if a log line is greater than that, it might be truncated in Sumo.
To fix this, fluent-bit exposes a parameter:  
``` bash
Docker_Mode  On
```
If enabled, the plugin will recombine split Docker log lines before passing them to any parser. This mode cannot be used at the same time as Multiline.
Reference: https://docs.fluentbit.io/manual/v/1.3/input/tail#docker_mode

### Fluentd autoscaling:

We have provided an option to enable autoscaling for Fluentd deployments. This is disabled by default. 

To enable autoscaling for Fluentd:

- Enable metrics-server dependency
  Note: If metrics-server is already installed, this step is not required.
  ```
  ## Configure metrics-server
  ## ref: https://github.com/helm/charts/blob/master/stable/metrics-server/values.yaml
  metrics-server:
    enabled: true
  ```

- Enable autoscaling for Fluentd
```
fluentd:
  ## Option to turn autoscaling on for fluentd and specify metrics for HPA.
  autoscaling:
    enabled: true
```


### Fluentd File-based buffer

By default, we use the in-memory buffer for the Fluentd buffer, however for production environments we recommend you use the file-based buffer instead.

The buffer configuration can be set in the `values.yaml` file under the `fluentd` key as follows:

```
fluentd:
  ## Option to specify the Fluentd buffer as file/memory.
  buffer: "file"
```

We have defined several file paths where the buffer chunks are stored.

Ensure that you have **enough space in the path directory**. Running out of disk space is a common problem.

Once the config has been modified in the `values.yaml` file you need to run the `helm upgrade` command to apply the changes.

```bash
$ helm upgrade collection sumologic/sumologic --reuse-values -f values.yaml
```

See the following links to official Fluentd buffer documentation: 
 - https://docs.fluentd.org/configuration/buffer-section
 - https://docs.fluentd.org/buffer/file

### Excluding Logs From Specific Components

You can exclude specific logs from being sent to Sumo Logic by specifying the following parameters either in the `values.yaml` file or the `helm install` command.
```
excludeContainerRegex
excludeHostRegex
excludeNamespaceRegex
excludePodRegex
```

 - This is Ruby regex, so all ruby regex rules apply. Unlike regex in the Sumo collector, you do not need to match the entire line. When doing multiple patterns, put them inside of parentheses and pipe separate them.
 - For things like pods and containers you will need to use a star at the end because the string is dynamic. Example:
```bash
excludepodRegex: "(dashboard.*|sumologic.*)"
```
 - For things like namespace you won’t need to use a star at the end since there is no dynamic string. Example:
```bash
excludeNamespaceRegex: “(sumologic|kube-public)”
```

### Add a local file to fluent-bit configuration

If you want to capture container logs to a container that writes locally, you will need to ensure the logs get mounted to the host so fluent-bit can be configured to capture from the host.

Example:
In the fluentbit overrides file (https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/fluent-bit/overrides.yaml) in the `rawConfig section`, you have to add a new input specifying the file path, eg.

```bash
[INPUT]
    Name        tail
    Path        /var/log/syslog
```
Reference: https://fluentbit.io/documentation/0.12/input/tail.html 

### Filtering Prometheus Metrics by Namespace in the Remote Write Config
If you want to filter metrics by namespace, it can be done in the prometheus remote write config. Here is an example of excluding kube-state metrics.
```bash
 - action: drop
   regex: kube-state-metrics;(namespace1|namespace2)
   sourceLabels: [job, namespace]
```
The above section should be added in each of the  kube-state remote write blocks.


### Send Data to AWS S3

If you wish to send data collected on your cluster to both Sumo Logic and an AWS S3 bucket, you may use the following example to configure FluentD to fork the data flow to sending to both S3 and Sumo. The following example presumes you have installed the collection solution.

1. Open the collection-sumologic configmap in edit mode
```
kubectl edit comfigmap collection-sumologic -n sumologic
```

Modify the last output plugin section in logs.source.containers.conf, adding the `<store>` section shown below

```
<match containers.**>
    @type copy
    <store>
      @type sumologic
      @id sumologic.endpoint.logs
      @include logs.output.conf
      <buffer>
        {{- if eq .Values.sumologic.fluentd.buffer "file" }}
        @type file
        path /fluentd/buffer/logs.containers
        {{- else }}
        @type memory
        {{- end }}
        @include buffer.output.conf
      </buffer>
    </store>
    <store>
      @type s3
      aws_key_id YOUR_AWS_KEY_ID
      aws_sec_key YOUR_AWS_SECRET_KEY
      s3_bucket YOUR_S3_BUCKET_NAME
      s3_region YOUR_S3_BUCKET_REGION
      path logs/
      # if you want to use ${tag} or %Y/%m/%d/ like syntax in path / s3_object_key_format,
      # need to specify tag for ${tag} and time for %Y/%m/%d in <buffer> argument.
      <buffer tag,time>
        @type file
        path /fluentd/buffer/logs.containers.s3
        timekey 3600 # 1 hour partition
        timekey_wait 10m
        timekey_use_utc true # use utc
        chunk_limit_size 256m
      </buffer>
    </store>
  </match>
```