# Telegraf

## Architecture

Sumologic Kubernetes Collection may use Telegraf to expose metrics from applications which are not
compatible with the prometheus format. In addition you can use all of the plugins which are
delivered with the Telegraf. After the metrics are obtained from a pod or an application
they are exposed in prometheus format via http `/metrics` endpoint.
All of such endpoints within every namespace are grouped together by special `service` named `telegraf-metrics`.
At the end dedicated `serviceMonitor` defines how often metrics are scrapped from the services.

### Enable telegraf operator

To enable Telegraf Operator you need to set `telegraf.enabled` to `true`, upgrade the collection and wait some time (just few minutes) for operator to be ready.

 ```yaml
 # ...
 telegraf:
   enabled: true
 ```

### Add telegraf sidecar

To add Telegraf sidecar you need to set few annotations in a pod specification:

 - `telegraf.influxdata.com/inputs` which is the configuration of the telegraf input plugins.
 For example:
```
[[inputs.redis]]
  servers = ["tcp://localhost:6379"]
```
 - `telegraf.influxdata.com/class` which should be set to `sumologic-prometheus`.
This annotation defines which of the output configuration is used to expose metrics.
 - `telegraf.influxdata.com/limits-cpu` which defines cpu usage of the sidecar container

 ### Expose Metrics

 There are two ways to expose metrics from telegraf to prometheus.
 You can do this via `Service` or by additional annotations.

 #### Expose sidecar using annotations

 To expose telegraf metrics you can simply add following annotations to a pod specification

 ```yaml
 # ...
 annotations:
   # ...
   prometheus.io/scrape: "true"
   prometheus.io/port: "9273"
 ```

 #### Expose sidecar by `telegraf-metrics` service

 After sidecar is configured it needs to be exposed to be accessible via `telegraf-metrics` service.
 In order to do it label `sumologic.com/service: telegraf` is used. This label should be add to
 the pod which metrics are scraped from. Additionaly the namespace should be add
 to the `telegraf.namespaces` list in the `values.yaml` and the collector upgraded.

 ```yaml
 # ...
 telegraf:
   namespaces:
     # ...
     - your_namespace
 ```
 
 **Note: Namespace has to be already create**

 ### Pass metrics from prometheus to the sumologic

 You need to update [prometheus configuration](./additional_prometheus_configuration.md) to pass metrics you are interested in.
