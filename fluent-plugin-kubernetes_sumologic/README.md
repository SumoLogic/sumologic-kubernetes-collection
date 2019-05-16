[![Build Status](https://travis-ci.org/SumoLogic/fluentd-kubernetes-sumologic.svg?branch=master)](https://travis-ci.org/SumoLogic/fluentd-kubernetes-sumologic) [![Gem Version](https://badge.fury.io/rb/fluent-plugin-kubernetes_sumologic.svg)](https://badge.fury.io/rb/fluent-plugin-kubernetes_sumologic) [![Docker Pulls](https://img.shields.io/docker/pulls/sumologic/fluentd-kubernetes-sumologic.svg)](https://hub.docker.com/r/sumologic/fluentd-kubernetes-sumologic) [![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/SumoLogic/fluentd-output-sumologic/issues)

This page describes the Sumo Kubernetes [Fluentd](http://www.fluentd.org/) plugin.

## Support
The code in this repository has been developed in collaboration with the Sumo Logic community and is not supported via standard Sumo Logic Support channels. For any issues or questions please submit an issue within the GitHub repository. The maintainers of this project will work directly with the community to answer any questions, address bugs, or review any requests for new features. 

## Installation

The plugin runs as a Kubernetes [DaemonSet](http://kubernetes.io/docs/admin/daemons/); it runs an instance of the plugin on each host in a cluster. Each plugin instance pulls system, kubelet, docker daemon, and container logs from the host and sends them, in JSON or text format, to an HTTP endpoint on a hosted collector in the [Sumo](http://www.sumologic.com) service.  Note the plugin with default configuration requires Kubernetes >=1.8.  See [the section below on running this on Kubernetes <1.8](#running-on-kubernetes-versions-<1.8)

- [Step 1  Create hosted collector and HTTP source in Sumo](#step-1--create-hosted-collector-and-http-source-in-sumo)
- [Step 2  Create a Kubernetes secret](#step-2--create-a-kubernetes-secret)
- [Step 3  Install the Sumo Kubernetes FluentD plugin](#step-3--install-the-sumo-kubernetes-fluentd-plugin)
  * [Option A  Install plugin using kubectl](#option-a--install-plugin-using-kubectl)
  * [Option B  Helm chart](#option-b--helm-chart)
- [Environment variables](#environment-variables)
    + [Override environment variables using annotations](#override-environment-variables-using-annotations)
    + [Exclude data using annotations](#exclude-data-using-annotations)
    + [Include excluded using annotations](#include-excluded-using-annotations)
- [Step 4 Set up Heapster for metric collection](#step-4-set-up-heapster-for-metric-collection)
  * [Kubernetes ConfigMap](#kubernetes-configmap)
  * [Kubernetes Service](#kubernetes-service)
  * [Kubernetes Deployment](#kubernetes-deployment)
- [Log data](#log-data)
  * [Docker](#docker)
  * [Kubelet](#kubelet)
  * [Containers](#containers)
- [Taints and Tolerations](#taints-and-tolerations)
- [Running On OpenShift](#running-on-openshift)



![deployment](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/blob/master/screenshots/kubernetes.png)

# Step 1  Create hosted collector and HTTP source in Sumo

In this step you create, on the Sumo service, an HTTP endpoint to receive your logs. This process involves creating an HTTP source on a hosted collector in Sumo. In Sumo, collectors use sources to receive data.

1. If you don’t already have a Sumo account, you can create one by clicking the **Free Trial** button on https://www.sumologic.com/.
2. Create a hosted collector, following the instructions on [Configure a Hosted Collector](https://help.sumologic.com/Send-Data/Hosted-Collectors/Configure-a-Hosted-Collector) in Sumo help. (If you already have a Sumo hosted collector that you want to use, skip this step.)  
3. Create an HTTP source on the collector you created in the previous step. For instructions, see [HTTP Logs and Metrics Source](https://help.sumologic.com/Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) in Sumo help. 
4. When you have configured the HTTP source, Sumo will display the URL of the HTTP endpoint. Make a note of the URL. You will use it when you configure the Kubernetes service to send data to Sumo. 

# Step 2  Create a Kubernetes secret

Create a secret in Kubernetes with the HTTP source URL. If you want to change the secret name, you must modify the Kubernetes manifest accordingly.

`kubectl create secret generic sumologic --from-literal=collector-url=INSERT_HTTP_URL`

You should see the confirmation message 

`secret "sumologic" created.`

# Step 3  Install the Sumo Kubernetes FluentD plugin

Follow the instructions in Option A below to install the plugin using `kubectl`. If you prefer to use a Helm chart, see Option B. 

Before you start, see [Environment variables](#environment-variables) for information about settings you can customize, and how to use annotations to override selected environment variables and exclude data from being sent to Sumo.

## Option A  Install plugin using kubectl

See the sample Kubernetes DaemonSet and Role in [fluentd.yaml](/daemonset/rbac/fluentd.yaml).

1. Clone the [GitHub repo](https://github.com/SumoLogic/fluentd-kubernetes-sumologic).

2. In `fluentd-kubernetes-sumologic`, install the chart using `kubectl`.

Which `.yaml` file you should use depends on whether or not you are running RBAC for authorization. RBAC is enabled by default as of Kubernetes 1.6.  Note the plugin with default configuration requires Kubernetes >=1.8. See the section below on [running this on Kubernetes <1.8](#running-on-kubernetes-versions-<1.8)
                                                                                                                                                      
**Non-RBAC (Kubernetes 1.5 and below)** 

`kubectl create -f /daemonset/nonrbac/fluentd.yaml` 

**RBAC (Kubernetes 1.6 and above)** <br/><br/>`kubectl create -f /daemonset/rbac/fluentd.yaml`


**Note** if you modified the command in Step 2 to use a different name, update the `.yaml` file to use the correct secret.

Logs should begin flowing into Sumo within a few minutes of plugin installation.

## Option B  Helm chart
If you use Helm to manage your Kubernetes resources, there is a Helm chart for the plugin at https://github.com/kubernetes/charts/tree/master/stable/sumologic-fluentd.

# Environment variables

Environment | Variable Description
----------- | --------------------
`AUDIT_LOG_PATH`|Define the path to the [Kubernetes Audit Log](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/) <br/><br/> Default: `/mnt/log/kube-apiserver-audit.log`
`CONCAT_SEPARATOR` |The character to use to delimit lines within the final concatenated message. Most multi-line messages contain a newline at the end of each line. <br/><br/> Default: ""
`EXCLUDE_CONTAINER_REGEX` |A regular expression for containers. Matching containers will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_FACILITY_REGEX`|A regular expression for syslog [facilities](https://en.wikipedia.org/wiki/Syslog#Facility). Matching facilities will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_HOST_REGEX`|A regular expression for hosts. Matching hosts will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_NAMESPACE_REGEX`|A regular expression for `namespaces`. Matching `namespaces` will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_PATH`|Files matching this pattern will be ignored by the `in_tail` plugin, and will not be sent to Kubernetes or Sumo. This can be a comma-separated list as well. See [in_tail](http://docs.fluentd.org/v0.12/articles/in_tail#excludepath) documentation for more information. <br/><br/> For example, defining `EXCLUDE_PATH` as shown below excludes all files matching `/var/log/containers/*.log`, <br/><br/>`...`<br/><br/>`env:`<br/>   - `name: EXCLUDE_PATH`<br/>         `value: "[\"/var/log/containers/*.log\"]"`
`EXCLUDE_POD_REGEX`|A regular expression for pods. Matching pods will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_PRIORITY_REGEX`|A regular expression for syslog [priorities](https://en.wikipedia.org/wiki/Syslog#Severity_level). Matching priorities will be excluded from Sumo. The logs will still be sent to FluentD.
`EXCLUDE_UNIT_REGEX` |A regular expression for `systemd` units. Matching units will be excluded from Sumo. The logs will still be sent to FluentD.
`FLUENTD_SOURCE`|Fluentd can use log tail, systemd query or forward as the source, Allowable values: `file`, `systemd`, `forward`. <br/><br/>Default: `file`
`FLUENTD_USER_CONFIG_DIR`|A directory of user-defined fluentd configuration files, which must be in the  `*.conf` directory in the container.
`FLUSH_INTERVAL` |How frequently to push logs to Sumo.<br/><br/>Default: `5s`
`KUBERNETES_META`|Include or exclude Kubernetes metadata such as `namespace` and `pod_name` if using JSON log format. <br/><br/>Default: `true`
`KUBERNETES_META_REDUCE`| Reduces redundant Kubernetes metadata, see [_Reducing Kubernetes Metadata_](#reducing-kubernetes-metadata). <br></br>Default: `false`
`LOG_FORMAT`|Format in which to post logs to Sumo. Allowable values:<br/><br/>`text`—Logs will appear in SumoLogic in text format.<br/>`json`—Logs will appear in SumoLogic in json format.<br/>`json_merge`—Same as json but if the container logs in json format to stdout it will merge in the container json log at the root level and remove the log field.<br/><br/>Default: `json`
`MULTILINE_START_REGEXP`|The regular expression for the `concat` plugin to use when merging multi-line messages. Defaults to Julian dates, for example, Jul 29, 2017.
`NUM_THREADS`|Set the number of HTTP threads to Sumo. It might be necessary to do so in heavy-logging clusters. <br/><br/>Default: `1`
`READ_FROM_HEAD`|Start to read the logs from the head of file, not bottom. Only applies to containers log files. See in_tail doc for more information.<br/><br/>Default: `true` 
`SOURCE_CATEGORY` |Set the `_sourceCategory` metadata field in Sumo. <br/><br/>Default: `"%{namespace}/%{pod_name}"`
`SOURCE_CATEGORY_PREFIX`|Prepends a string that identifies the cluster to the `_sourceCategory` metadata field in Sumo.<br/><br/>Default:  `kubernetes/`
`SOURCE_CATEGORY_REPLACE_DASH` |Used to replace a dash (-) character with another character. <br/><br/>Default:  `/`<br/><br/>For example, a Pod called `travel-nginx-3629474229-dirmo` within namespace `app` will appear in Sumo with `_sourceCategory=app/travel/nginx`.
`SOURCE_HOST`|Set the `_sourceHost` metadata field in Sumo.<br/><br/>Default: `""`
`SOURCE_NAME`|Set the `_sourceName` metadata field in Sumo. <br/><br/> Default: `"%{namespace}.%{pod}.%{container}"`
`TIME_KEY`|The field name for json formatted sources that should be used as the time. See [time_key](https://docs.fluentd.org/v0.12/articles/formatter_json#time_key-(string,-optional,-defaults-to-%E2%80%9Ctime%E2%80%9D)). Default: `time`
`ADD_TIMESTAMP`|Option to control adding timestamp to logs. Default: `true`
`TIMESTAMP_KEY`|Field name when add_timestamp is on. Default: `timestamp`
`ADD_STREAM`|Option to control adding stream to logs. Default: `true`
`ADD_TIME`|Option to control adding time to logs. Default: `true`
`CONTAINER_LOGS_PATH`|Specify the path in_tail should watch for container logs. Default: `/mnt/log/containers/*.log`
`PROXY_URI`|Add the uri of the proxy environment if present.
`ENABLE_STAT_WATCHER`|Option to control the enabling of [stat_watcher](https://docs.fluentd.org/v1.0/articles/in_tail#enable_stat_watcher). Default: `true`
`K8S_METADATA_FILTER_WATCH`|Option to control the enabling of [metadata filter plugin watch](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration). Default: `true`
`K8S_METADATA_FILTER_CA_FILE`|Option to control the enabling of [metadata filter plugin ca_file](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration).
`K8S_METADATA_FILTER_VERIFY_SSL`|Option to control the enabling of [metadata filter plugin verify_ssl](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration). Default: `true`
`K8S_METADATA_FILTER_CLIENT_CERT`|Option to control the enabling of [metadata filter plugin client_cert](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration).
`K8S_METADATA_FILTER_CLIENT_KEY`|Option to control the enabling of [metadata filter plugin client_key](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration).
`K8S_METADATA_FILTER_BEARER_TOKEN_FILE`|Option to control the enabling of [metadata filter plugin bearer_token_file](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration).
`K8S_METADATA_FILTER_BEARER_CACHE_SIZE`|Option to control the enabling of [metadata filter plugin cache_size](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration). Default: `1000`
`K8S_METADATA_FILTER_BEARER_CACHE_TTL`|Option to control the enabling of [metadata filter plugin cache_ttl](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#configuration). Default: `3600`
`K8S_NODE_NAME`|If set, improves [caching of pod metadata](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter#environment-variables-for-kubernetes) and reduces API calls. 
`VERIFY_SSL`|Verify ssl certificate of sumologic endpoint. Default: `true`
`FORWARD_INPUT_BIND`|The bind address to listen to if using forward as `FLUENTD_SOURCE`. Default: `0.0.0.0` (all addresses)
`FORWARD_INPUT_PORT`|The port to listen to if using forward as `FLUENTD_SOURCE`. Default: `24224`


The following table show which  environment variables affect which Fluentd sources.

| Environment Variable | Containers | Docker | Kubernetes | Systemd |
|----------------------|------------|--------|------------|---------|
| `EXCLUDE_CONTAINER_REGEX` | ✔ | ✘ | ✘ | ✘ |
| `EXCLUDE_FACILITY_REGEX` | ✘ | ✘ | ✘ | ✔ |
| `EXCLUDE_HOST_REGEX `| ✔ | ✘ | ✘ | ✔ |
| `EXCLUDE_NAMESPACE_REGEX` | ✔ | ✘ | ✔ | ✘ |
| `EXCLUDE_PATH` | ✔ | ✔ | ✔ | ✘ |
| `EXCLUDE_PRIORITY_REGEX` | ✘ | ✘ | ✘ | ✔ |
| `EXCLUDE_POD_REGEX` | ✔ | ✘ | ✘ | ✘ |
| `EXCLUDE_UNIT_REGEX` | ✘ | ✘ | ✘ | ✔ |
| `TIME_KEY` | ✔ | ✘ | ✘ | ✘ |

### FluentD stops processing logs
When dealing with large volumes of data (TB's from what we have seen), FluentD may stop processing logs, but continue to run.  This issue seems to be caused by the [scalability of the inotify process](https://github.com/fluent/fluentd/issues/1630) that is packaged with the FluentD in_tail plugin.  If you encounter this situation, setting the `ENABLE_STAT_WATCHER` to `false` should resolve this issue.

### Reducing Kubernetes metadata

You can use the `KUBERNETES_META_REDUCE` environment variable (global) or the `sumologic.com/kubernetes_meta_reduce` annotation (per pod) to reduce the amount of Kubernetes metadata included with each log line under the `kubernetes` field. 

When set, FluentD will remove the following properties:

* `pod_id`
* `container_id`
* `namespace_id`
* `master_url`
* `labels`
* `annotations`

Logs will still include:

* `pod_name`
* `container_name`
* `namespace_name`
* `host`

These fields still allow you to uniquely identify a pod and look up additional details with the Kubernetes API.

```yaml
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
        sumologic.com/kubernetes_meta_reduce: "true"
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
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

### Exclude data using annotations

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

### Include excluded using annotations

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

# Step 4 Set up Heapster for metric collection

The recommended way to collect metrics from Kubernetes clusters is to use Heapster and a Sumo collector with a Graphite source. 

Heapster aggregates metrics across a Kubenetes cluster. Heapster runs as a pod in the cluster, and  discovers all nodes in the cluster and queries usage information from each node's `kubelet`—the on-machine Kubernetes agent. 

Heapster provides metrics at the cluster, node and pod level.

1. Install Heapster in your Kubernetes cluster and configure a Graphite Sink to send the data in Graphite format to Sumo. For instructions, see 
https://github.com/kubernetes/heapster/blob/master/docs/sink-configuration.md#graphitecarbon. Assuming you have used the below YAML files to configure your system, then the sink option in graphite would be `--sink=graphite:tcp://sumo-graphite.kube-system.svc:2003`.  You may need to change this depending on the namespace you run the deployment in, the name of the service or the port number for your Graphite source.

2. Use the Sumo Docker container. For instructions, see https://hub.docker.com/r/sumologic/collector/.

3. The following sections contain an  example configmap, which contains the `sources.json` configuration, an example service, and an example deployment. Create these manifests in Kubernetes using `kubectl`.


## Kubernetes ConfigMap
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: "sumo-sources"
data:
  sources.json: |-
    {
      "api.version": "v1",
      "sources": [
        {
          "name": "SOURCE_NAME",
          "category": "SOURCE_CATEGORY",
          "automaticDateParsing": true,
          "contentType": "Graphite",
          "timeZone": "UTC",
          "encoding": "UTF-8",
          "protocol": "TCP",
          "port": 2003,
          "sourceType": "Graphite"
        }
      ]
    }

```
## Kubernetes Service
```
apiVersion: v1
kind: Service
metadata:
  name: sumo-graphite
spec:
  ports:
    - port: 2003
  selector:
    app: sumo-graphite
```
## Kubernetes Deployment
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: sumo-graphite
  name: sumo-graphite
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: sumo-graphite
    spec:
      volumes:
      - name: sumo-sources
        configMap:
          name: sumo-sources
          items:
          - key: sources.json
            path: sources.json
      containers:
      - name: sumo-graphite
        image: sumologic/collector:latest
        ports:
        - containerPort: 2003
        volumeMounts:
        - mountPath: /sumo
          name: sumo-sources
        env:
        - name: SUMO_ACCESS_ID
          value: <SUMO_ACCESS_ID>
        - name: SUMO_ACCESS_KEY
          value: <SUMO_ACCESS_KEY>
        - name: SUMO_SOURCES_JSON
          value: /sumo/sources.json

```

# Templating Kubernetes metadata
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

## Missing labels
Unlike the other templates, labels are not guaranteed to exist, so missing labels interpolate as `"undefined"`.

For example, if you have only the label `app: travel` but you define `SOURCE_NAME="%{label:app}@%{label:version}"`, the source name will appear as `travel@undefined`.

# Log data
After performing the configuration described above, your logs should start streaming to SumoLogic in `json` or text format with the appropriate metadata. If you are using `json` format you can auto extract fields, for example `_sourceCategory=some/app | json auto`.

## Docker
![Docker Logs](/screenshots/docker.png)

## Kubelet
Note that Kubelet logs are only collected if you are using systemd.  Kubernetes no longer outputs the kubelet logs to a file.
![Docker Logs](/screenshots/kubelet.png)

## Containers
![Docker Logs](/screenshots/container.png)

# Taints and Tolerations
By default, the fluentd pods will schedule on, and therefore collect logs from, any worker nodes that do not have a taint and any master node that does not have a taint beyond the default master taint. If you would like to schedule pods on all nodes, regardless of taints, uncomment the following line from fluentd.yaml before applying it.

```
tolerations:
           #- operator: "Exists"
```

# Running On OpenShift

This daemonset setting mounts /var/log as service account FluentD so you need to run containers as privileged container. Here is command example:

```
oc adm policy add-scc-to-user privileged system:serviceaccount:logging:fluentd
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:logging:fluentd
oc label node —all logging-sumologic-fluentd=true
oc patch ds fluentd-sumologic -p "spec:
  template:
    spec:
      containers:
      - image: sumologic/fluentd-kubernetes-sumologic:latest
        name: fluentd
        securityContext:
          privileged: true"
oc delete pod -l name = fluentd-sumologic
```

## Running on Kubernetes versions <1.8

In order to run this plugin on Kubernetes <1.8 you will need to make some changes the yaml file prior to deploying it.

Replace:

```
      - name: pos-files
        hostPath:
          path: /var/run/fluentd-pos
          type: ""
```
With:

```
      - name: pos-files
        emptyDir: {}
```

## Output to S3

If you need to also send data to S3 (i.e. as a secondary backup/audit trail) the image includes the `fluent-plugin-s3` plugin.  In order to send the logs from FluentD to multiple outputs, you must use the `copy` plugin.  This image comes with an [OOB configuration](conf.d/out.sumo.conf) to output the logs to Sumo Logic. In order to output to multiple destinations, you need to modify that existing configuration.

**Example:** Send all logs to S3 and Sumo:

```
<match **>
  @type copy
  <store>
    @type sumologic
    log_key log
    endpoint "#{ENV['COLLECTOR_URL']}"
    verify_ssl "#{ENV['VERIFY_SSL']}"
    log_format "#{ENV['LOG_FORMAT']}"
    flush_interval "#{ENV['FLUSH_INTERVAL']}"
    num_threads "#{ENV['NUM_THREADS']}"
    open_timeout 60
    add_timestamp "#{ENV['ADD_TIMESTAMP']}"
    proxy_uri "#{ENV['PROXY_URI']}"
  </store>
  <store>
    @type s3
  
    aws_key_id YOUR_AWS_KEY_ID
    aws_sec_key YOUR_AWS_SECRET_KEY
    s3_bucket YOUR_S3_BUCKET_NAME
    s3_region us-west-1
    path logs/
    buffer_path /var/log/fluent/s3
  
    time_slice_format %Y%m%d%H
    time_slice_wait 10m
    utc
  
    buffer_chunk_limit 256m
  </store>
</match>
```

You can replace the OOB configuration by creating a new Docker image from our image or by using a configmap to inject the new configuration to the pod.

More details about the S3 plugin can be found [in the docs](https://docs.fluentd.org/v0.12/articles/out_s3).

## Upgrading to v2.0.0

In version 2.0.0, some legacy FluentD configuration has been removed that could lead to [duplicate logs being ingested into Sumo Logic](https://github.com/SumoLogic/fluentd-kubernetes-sumologic/issues/79).  These logs were control plane components.  This version was done as a major release as it breaks the current version of the [Kubernetes App](https://help.sumologic.com/Send-Data/Applications-and-Other-Data-Sources/Kubernetes/Install_the_Kubernetes_App_and_View_the_Dashboards) you may have installed in Sumo Logic.

After upgrading to this version, you will need to reinstall the [Kubernetes App](https://help.sumologic.com/Send-Data/Applications-and-Other-Data-Sources/Kubernetes/Install_the_Kubernetes_App_and_View_the_Dashboards) in Sumo Logic. If you do not some of the panels in the dashboards will not render properly.

If you have other content outside the app (Partitions, Scheduled Views, Field Extraction Rules or Scheduled Searches and Alerts), these may need to be updated after upgrading to v2.0.0.  The logs, while the same content, have a different format and the same parsing logic and metadata may not apply.

The previous log format that is removed in v2.0.0:
```json
{
   "timestamp": 1538776281387,
   "severity": "I",
   "pid": "1",
   "source": "wrap.go:42",
   "message": "GET /api/v1/namespaces/kube-system/endpoints/kube-scheduler: (3.514372ms) 200 [[kube-scheduler/v1.10.5 (linux/amd64) kubernetes/32ac1c9/leader-election] 127.0.0.1:46290]"
}
```
Is replaced by the following version.  It is the same log line in a different format enriched with the same metadata the plugin applies to all pod logs.
```json
{
   "timestamp": 1538776282152,
   "log": "I1005 21:51:21.387204       1 wrap.go:42] GET /api/v1/namespaces/kube-system/endpoints/kube-scheduler: (3.514372ms) 200 [[kube-scheduler/v1.10.5 (linux/amd64) kubernetes/32ac1c9/leader-election] 127.0.0.1:46290]",
   "stream": "stdout",
   "time": "2018-10-05T21:51:21.387477546Z",
   "docker": {
      "container_id": "a442fd2982dfdc09ab6235941f8d661a0a5c8df5e1d21f23ff48a9923ac14739"
   },
   "kubernetes": {
      "container_name": "kube-apiserver",
      "namespace_name": "kube-system",
      "pod_name": "kube-apiserver-ip-172-20-122-71.us-west-2.compute.internal",
      "pod_id": "80fa5e13-c8b9-11e8-a456-0a8c1424d0d4",
      "labels": {
         "k8s-app": "kube-apiserver"
      },
      "host": "ip-172-20-122-71.us-west-2.compute.internal",
      "master_url": "https://100.64.0.1:443/api",
      "namespace_id": "9b9b75b7-aa16-11e8-9d62-06df85b5d3bc"
   }
}
```
