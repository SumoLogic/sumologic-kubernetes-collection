# Advanced Configuration / Best Practices

### Topics
- [Multiline Log Support](#Multiline-Log-Support)
- [Collecting Log Lines over 16KB](#Log-Lines-Over-16KB)
- [Fluentd Autoscaling](#Fluentd-Autoscaling)
- [Fluentd File-Based Buffer](#Fluentd-File-based-buffer) 
- [Excluding Logs From Specific Components](#Excluding-Logs-From-Specific-Components)
- [Filtering Prometheus Metrics by Namespace](#Filtering-Prometheus-Metrics-by-Namespace)
- [Modify the Log Level for Falco](#Modify-the-Log-Level-for-Falco)
- [Override environment variables using annotations](#Override-environment-variables-using-annotations)
- [Templating Kubernetes metadata](#Templating-Kubernetes-metadata)
- [Configure Ignore_Older Config for Fluentbit](#Configure-Ignore_Older-Config-for-fluentbit)
- [Disable logs, metrics, or falco](#Disable-logs-metrics-or-falco)


### Multiline Log Support

By default, we use a regex that matches the first line of multiline logs that start with dates in the following format: `2019-11-17 07:14:12`.

If your logs have a different date format you can provide a custom regex to detect the first line of multiline logs. See [collecting multiline logs](https://help.sumologic.com/?cid=49494) for details on configuring a boundary regex.

New parsers can be defined under the `parsers` key of the fluent-bit configuration section in the `values.yaml` file as follows:

```yaml
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
### Collecting Log Lines Over 16KB (with multiline support)
Docker daemon has a limit of 16KB/line so if a log line is longer than that, it might be truncated in Sumo.
To fix this, fluent-bit exposes a parameter:  
``` bash
Docker_Mode  On
```
If enabled, the plugin will recombine split Docker log lines before passing them to any parser.

#### Multiline Support

To add multiline support to docker mode, you need to follow [the multiline support](#multiline-log-support) section and assign created parser to the `Docker_Mode_Parser` parameter in the `Input plugin` configuration of fluent-bit:

```
Docker_Mode_Parser multi_line
```

### Fluentd Autoscaling

We have provided an option to enable autoscaling for both logs and metrics Fluentd statefulsets. This is disabled by default. 

To enable autoscaling for Fluentd:

- Enable metrics-server dependency

  Note: If metrics-server is already installed, this step is not required.

```yaml
## Configure metrics-server
## ref: https://github.com/helm/charts/blob/master/stable/metrics-server/values.yaml
metrics-server:
  enabled: true
```

- Allow metrics-server communication with kubelet for [KOPS](https://github.com/kubernetes/kops)

  Note: This step is required only for KOPS clusters

```yaml
## This goes to the kops cluster configuration file
kubelet:
   # ...
   ## Enable webhook authorization for KOPS cluster
   ## rel: https://github.com/kubernetes/kops/issues/7200
   authenticationTokenWebhook: true
   authorizationMode: Webhook
```

- Enable autoscaling for Logs Fluentd statefulset 
```yaml
fluentd:
  logs:
    ## Option to turn autoscaling on for fluentd and specify metrics for HPA.
    autoscaling:
      enabled: true
```

- Enable autoscaling for Metrics Fluentd statefulset 
```yaml
fluentd:
  metrics:
    ## Option to turn autoscaling on for fluentd and specify metrics for HPA.
    autoscaling:
      enabled: true
```


### Fluentd File-Based Buffer

By default, we use the in-memory buffer for the Fluentd buffer, however for production environments we recommend you use the file-based buffer instead.

The buffer configuration can be set in the `values.yaml` file under the `fluentd` key as follows:

```yaml
fluentd:
  ## Persist data to a persistent volume; When enabled, fluentd uses the file buffer instead of memory buffer.
  persistence:
    ## After setting the value to true, run the helm upgrade command with the --force flag.
    enabled: true
```

Additional buffering and flushing parameters can be added in the `extraConf`, in the `fluentd` buffer section.
```yaml
fluentd:
## Option to specify the Fluentd buffer as file/memory.
   buffer: 
     type : "file"
     extraConf: |-
       retry_exponential_backoff_base 2s
```

We have defined several file paths where the buffer chunks are stored.

Once the config has been modified in the `values.yaml` file you need to run the `helm upgrade` command to apply the changes.

```bash
$ helm upgrade collection sumologic/sumologic --reuse-values -f values.yaml --force
```

See the following links to official Fluentd buffer documentation: 
 - https://docs.fluentd.org/configuration/buffer-section
 - https://docs.fluentd.org/buffer/file

### Excluding Logs From Specific Components

You can exclude specific logs from specific components from being sent to Sumo Logic by specifying the following parameters either in the `values.yaml` file or the `helm install` command.
```
excludeContainerRegex
excludeHostRegex
excludeNamespaceRegex
excludePodRegex
```

 - This is Ruby regex, so all ruby regex rules apply. Unlike regex in the Sumo collector, you do not need to match the entire line. When doing multiple patterns, put them inside of parentheses and pipe separate them.
 - For things like pods and containers you will need to use a star at the end because the string is dynamic. Example:
```yaml
excludepodRegex: "(dashboard.*|sumologic.*)"
```
 - For things like namespace you won’t need to use a star at the end since there is no dynamic string. Example:
```yaml
excludeNamespaceRegex: “(sumologic|kube-public)”
```

If you wish to exclude messages based on the content of the message, you can leverage the fluentd `grep` filter plugin.  We expose `fluentd.logs.containers.extraFilterPluginConf` which allows you to inject additional filter plugins to process data. For example suppose you want to exclude the following log messages:

```
.*connection accepted from.*
.*authenticated as principal.*
.*client metadata from.*
```

In your values.yaml, you can simply add the following to your `values.yaml`:

```
fluentd:
  logs:
    containers:
      extraFilterPluginConf: |-
        <filter containers.**>
          @type grep
          <exclude>
            key message
            pattern /(.*connection accepted from.*|.*authenticated as principal.*|.*client metadata from.*)/
          </exclude>
        </filter>
```

You can find more information on the `grep` filter plugin in the [fluentd documentation](https://docs.fluentd.org/filter/grep). Refer to our [documentation](v1_conf_examples.md) for other examples of how you can customize the fluentd pipeline.

### Add a local file to fluent-bit configuration

If you want to capture container logs to a container that writes locally, you will need to ensure the logs get mounted to the host so fluent-bit can be configured to capture from the host.

Example:
In `values.yaml` in the `fluent-bit.rawConfig` section, you have to add a new input specifying the file path, eg.

```bash
[INPUT]
    Name        tail
    Path        /var/log/syslog
```
Reference: https://fluentbit.io/documentation/0.12/input/tail.html 

### Filtering Prometheus Metrics by Namespace
If you want to filter metrics by namespace, it can be done in the prometheus remote write config. Here is an example of excluding kube-state metrics for namespace1 and namespace2:
```yaml
 - action: drop
   regex: kube-state-metrics;(namespace1|namespace2)
   sourceLabels: [job, namespace]
```

The section above should be added in each of the kube-state remote write blocks.

Here is another example of excluding up metrics in the sumologic namespace while still collecting up metrics for all other namespaces:
```yaml
     # up metrics
     - url: http://collection-sumologic.sumologic.svc.cluster.local:9888/prometheus.metrics
       writeRelabelConfigs:
       - action: keep
         regex: up
         sourceLabels: [__name__]
       - action: drop
         regex: up;sumologic
         sourceLabels: [__name__,namespace]
```
The section above should be added in each of the kube-state remote write blocks.

### Modify the Log Level for Falco
To modify the default log level for Falco, edit the following section in the values.yaml file. Available log levels can be found in Falco's documentation here: https://falco.org/docs/configuration/.
```yaml
falco:
  ## Set the enabled flag to false to disable falco.
  enabled: true
  #ebpf:
  #  enabled: true
  falco:
    jsonOutput: true
    loglevel: debug
```

### Override environment variables using annotations
You can override the `LOG_FORMAT`, `KUBERNETES_META_REDUCE`, `SOURCE_CATEGORY` and `SOURCE_NAME` environment variables, per pod, using [Kubernetes annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/). For example:

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/format: "text"
        sumologic.com/kubernetes_meta_reduce: "true"
        sumologic.com/sourceCategory: "mywebsite/nginx"
        sumologic.com/sourceName: "mywebsite_nginx"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

#### Exclude data using annotations

You can also use the `sumologic.com/exclude` annotation to exclude data from Sumo. This data is sent to FluentD, but not to Sumo.

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/format: "text"
        sumologic.com/sourceCategory: "mywebsite/nginx"
        sumologic.com/sourceName: "mywebsite_nginx"
        sumologic.com/exclude: "true"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

#### Include excluded using annotations

If you excluded a whole namespace, but still need one or few pods to be still included for shipping to Sumologic, you can use the `sumologic.com/include` annotation to include data to Sumo. It takes precedence over the exclusion described above.

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    app: mywebsite
  template:
    metadata:
      name: nginx
      labels:
        app: mywebsite
      annotations:
        sumologic.com/format: "text"
        sumologic.com/sourceCategory: "mywebsite/nginx"
        sumologic.com/sourceName: "mywebsite_nginx"
        sumologic.com/include: "true"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

### Templating Kubernetes metadata
The following Kubernetes metadata is available for string templating:
 
| String template  | Description                                             |
| ---------------  | ------------------------------------------------------  |                                         
| `%{namespace}`   | Namespace name                                          |
| `%{pod}`         | Full pod name (e.g. `travel-products-4136654265-zpovl`) | 
| `%{pod_name}`    | Friendly pod name (e.g. `travel-products`)              | 
| `%{pod_id}`      | The pod's uid (a UUID)                                  | 
| `%{container}`   | Container name                                          |
| `%{source_host}` | Host                                                    |
| `%{label:foo}`   | The value of label `foo`                                | 

#### Missing labels
Unlike the other templates, labels are not guaranteed to exist, so missing labels interpolate as `"undefined"`.

For example, if you have only the label `app: travel` but you define `SOURCE_NAME="%{label:app}@%{label:version}"`, the source name will appear as `travel@undefined`.

### Configure Ignore_Older Config for Fluentbit
We have observed that the  `Ignore_Older` config does not work when `Multiline` is set to `On`.
Default config:
```
    [INPUT]
        Name             tail
        Path             /var/log/containers/*.log
        Multiline        On
        Parser_Firstline multi_line
        Tag              containers.*
        Refresh_Interval 1
        Rotate_Wait      60
        Mem_Buf_Limit    5MB
        Skip_Long_Lines  On
        DB               /tail-db/tail-containers-state-sumo.db
        DB.Sync          Normal
```
Please make the below changes to the `INPUT` section to turn off `Multiline` and add a `docker` parser to parse the time for `Ignore_Older` functionality to work properly.  
<pre>
[INPUT]
    Name             tail
    Path             /var/log/containers/*.log
    <b>Multiline        Off</b>
    Parser_Firstline multi_line
    Tag              containers.*
    Refresh_Interval 1
    Rotate_Wait      60
    Mem_Buf_Limit    5MB
    Skip_Long_Lines  On
    DB               /tail-db/tail-containers-state-sumo.db
    DB.Sync          Normal
    <b>Ignore_Older     24h</b>
    <b>Parser           Docker</b>
</pre>
Ref: https://docs.fluentbit.io/manual/pipeline/inputs/tail

###  Disable logs, metrics, or falco
If you want to disable the collection of logs, metrics, or falco, make the below changes respectively in the `values.yaml` file and run the `helm upgrade` command.
| parameter  |  value | function |
| ------------ | ------------ | ------------ |
|  sumologic.logs.enabled |  false | disable logs collection |
|  sumologic.metrics.enabled |  false | disable metrics collection |
| falco.enabled  |  false | disable falco |
