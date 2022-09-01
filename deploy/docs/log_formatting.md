# Log formatting

This document descibes all log formatting options for otel collector as well as fluentd. The same input (below) will be used for all examples, therefore differences will be easily visible.

```json
{
   "time":"2022-09-01 12:53:17.729842896 +0000 UTC m=+11064.774193142",
   "composite":{
      "value1":1,
      "value2":2
   },
   "message":"log body",
   "value":0
}
```

## Otel collector

Otel collector provides two formatting options:

- json (enabled by default)
- text

Due to the fact that json is enabled by default (it's configured implicitely), 
minimal configuration that will emit it is:

```yaml
fluent-bit:
  enabled: false

sumologic:
  logs:
    metadata:
      provider: otelcol
    collector:
      otelcol:
        enabled: true
```

The same thing is possible by giving explicit configuration.

```yaml
fluent-bit:
  enabled: false

sumologic:
  logs:
    metadata:
      provider: otelcol
    collector:
      otelcol:
        enabled: true
metadata:
  logs:
    config:
      exporters:
        sumologic/containers:
          log_format: json        
```

Output in backend:

```json
{
   "fluent.tag":"containers.logwriter-app",
   "k8s.pod.uid":"8795e281-dd5d-4795-b025-8c00f7a46ab4",
   "log":"{\"time\":\"2022-09-01 05:49:57.768645195 +0000 UTC m=+1285.863594223\", \"composite\":{\"value1\":1, \"value2\":2},\"message\":\"log body\", \"value\":0}",
   "run_id":"0",
   "stream":"stdout",
   "timestamp":1662011397768
}
```

Log content emitted by application (pod) is visible under log key. All other keys belongs to record
attribures category. Another category is resource attributes. Resource attributes are displayed as fields
on left side in backend.

To enable second format - text, log_format setting has to be changed appropriately.

```yaml
   log_format: text
```

Output in backend:

```json
{
   "time":"2022-09-01 08:39:58.312103061 +0000 UTC m=+10823.688354551",
   "composite":{
      "value1":1,
      "value2":2
   },   
   "message":"log body",
   "value":0
}
```

## FluentD 

FluentD provides four different formatting options, however some of them overlapping each others:
- fields (default one)
- json (the same as fields)
- json_merge
- text

As fluentd is enabled by default field option will work out of the box. The same can be done explicitely by

```yaml
fluentd:
  logs:
    output:
      logFormat: fields
```

Output in backend:

```json
{
   "timestamp":1661958077902,
   "stream":"stdout",
   "logtag":"F",
   "log":{
      "time":"2022-08-31 15:01:17.902368064 +0000 UTC m=+4284.098610273",
      "composite":{
         "value1":1,
         "value2":2
      },      
      "message":"log body",
      "value":0
   },
   "docker":{
      "container_id":"f548848a-26b6-44b4-a9eb-39c5be0862f6"
   },
   "kubernetes":{
      "container_name":"logwriter-app",
      "namespace_name":"sumologic",
      "pod_name":"logwriter-app-deployment-cd569c759-f9c8w",
      "pod_id":"f548848a-26b6-44b4-a9eb-39c5be0862f6",
      "host":"sumologic-kubernetes-collection2",
      "labels":{
         "app":"logwriter-app",
         "pod-template-hash":"cd569c759"
      },
      "master_url":"https://10.152.183.1:443/api",
      "namespace_id":"92d6a117-0bd0-484e-bd7e-283ce8e84c03",
      "namespace_labels":{
         "kubernetes.io/metadata.name":"sumologic"
      },
      "replicaset":"logwriter-app-deployment-cd569c759",
      "deployment":"logwriter-app-deployment"
   }
}
```

Using any other type requires logFormat key change. Below output for:

- json_merge 

```json
{
   "time":"2022-08-31 14:25:57.405983069 +0000 UTC m=+2163.602225271",
   "composite":{
      "value1":1,
      "value2":2
   },
   "message":"log body",
   "value":0
   ...record attributes
}
```

- text

```json
{
   "time":"2022-09-01 05:28:17.173881932 +0000 UTC m=+11639.118339333",
   "composite":{
      "value1":1,
      "value2":2
   },
   "message":"log body",
   "value":0   
}
```
