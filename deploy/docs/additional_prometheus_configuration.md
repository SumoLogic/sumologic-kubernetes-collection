# Additional Prometheus Configuration

## Configuration

Prometheus configuration is located in `values.yaml` under `prometheus-operator` key for helm installation.

If the `prometheus-operator` has been installed directly, a `prometheus-overrides.yaml` should be generated
using `docker`/`kubectl` and [sumologic-kubernetes-tools](https://github.com/sumologic/sumologic-kubernetes-tools#template-dependency-configuration):

```bash
 # using kubectl
 kubectl run template-dependency \
  -it --quiet --rm \
  --restart=Never -n sumologic \
  --image sumologic/kubernetes-tools:master \
  -- template-dependency prometheus-operator > prometheus-overrides.yaml

 # or using docker
 docker run -it --rm \
  sumologic/kubernetes-tools:master \
  template-dependency prometheus-operator > prometheus-overrides.yaml
```

All changes described in this documentation should be introduced in those files depending of used deployment.

## Filter metrics

The configuration contains a section like the following for each of the Kubernetes components that report metrics in this solution: API server, Controller Manager, and so on.

If you would like to collect other metrics that are not listed in configuration, you can add a new section to the file.

```yaml
prometheus-operator:  # For values.yaml
    # ...
    prometheus:
      # ...
      prometheusSpec:
        # ...
        remoteWrite:
          # ...
          - url: http://$(CHART).$(NAMESPACE).svc.cluster.local/prometheus.metrics.<some_label>
            writeRelabelConfigs:
            - action: keep
              regex: <metric1>|<metric2>|...
              sourceLabels: [__name__]
```

The syntax of `writeRelabelConfigs` can be found [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write).
You can supply any label you like. You can query Prometheus to see a complete list of metrics it’s scraping.

## Trim and relabel metrics

You can specify relabeling, and additional inclusion or exclusion options in `fluentd-sumologic.yaml`.

The options you can use are described [here](../../fluent-plugin-prometheus-format/README.md).

Make your edits in the `<filter>` stanza in the ConfigMap section of `fluentd-sumologic.yaml`.

```xml
<filter prometheus.datapoint**>
  @type prometheus_format
  relabel container_name:container,pod_name:pod
</filter>
```

Sumo is using `relabel` parameter to standardize the metadata fields (`container_name` -> `container`,`pod_name` -> `pod`).
You can use `inclusion` or `exclusion` configuration options to further filter metrics by labels. For example:

```xml
<filter prometheus.datapoint**>
  @type prometheus_format
  relabel service,container_name:container,pod_name:pod
  inclusions { "namespace" : "kube-system" }
</filter>
```

This filter will:

* Trim the service metadata from the metric datapoint.
* Rename the label/metadata `container_name` to `container`, and `pod_name` to `pod`.
* Only apply to metrics with the `kube-system` namespace

## Custom Metrics

If you have custom metrics you'd like to send to Sumo via Prometheus, you just need to expose a `/metrics` endpoint in prometheus format, and instruct prometheus via a ServiceMonitor to pull data from the endpoint. In this section, we'll walk through collecting custom metrics with Prometheus.

### Expose a `/metrics` endpoint on your service

There are many pre-built libraries that the community has built to expose these, but really any output that aligns with the prometheus format can work. Here is a list of libraries: [Libraries](https://prometheus.io/docs/instrumenting/clientlibs). Manually verify that you have metrics exposed in Prometheus format by hitting the metrics endpoint, and verifying that the output follows the [Prometheus format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md).

### Set up a service monitor so that Prometheus pulls the data

#### ServiceMonitor

To expose metrics to prometheus, you need to have some service. Let's say here is our example service configuration:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: example-metrics
  # This is important, because prometheus matches service via labels
  labels:
    app: example-metrics
spec:  # Should match your deployment
  ports:
    - name: "8000"
      port: 8000
      targetPort: 8000
  selector:
    service: example-metrics
status:
  loadBalancer: {}
```

Service Monitors is how we tell Prometheus what endpoints and sources to pull metrics from. To define a Service Monitor, create a yaml file with information templated as follows:

```yaml
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-metrics
  labels:
    release: collection  # ensure this matches the `release` label on your Prometheus pod
spec:
  selector:
    matchLabels:
      app: example-metrics
  endpoints:
  - port: "8000"  # Same as service's port name
  ```

By default, prometheus attempts to scrape metrics off of the `/metrics` endpoint, but if you do need to use a different url, you can override it by providing a `path` attribute in the settings like so:

```yaml
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
spec:
  # ...
  endpoints:
  - path: /metrics/cadvisor
    port: https-metrics
# ...
```

Detailed instructions on service monitors can be found via [Prometheus-Operator](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources) website.
Once you have created this yaml file, go ahead and run `kubectl create -f name_of_yaml.yaml -n sumologic`. This will create the service monitor in the sumologic namespace.

If you want to keep all your changes inside configuration instead of serviceMonitors, you can add your changes to `prometheus.additionalServiceMonitors` section. For given serviceMonitor configuration it should looks like snippet below:

```yaml
prometheus-operator:  # For values.yaml
  # ...
  prometheus:
    # ...
    additionalServiceMonitors:
      # ...
      - name: my-metrics
        additionalLabels:
          app: my-metrics
        endpoints:
        - port: "8000"
        selector:
          matchLabels:
            app: example-metrics
```

#### Annotations

Alternatively to Service and ServiceMonitor you can use dedicated annotations in your pod:

```yaml
# ...
annotations:
  prometheus.io/port: 8000 # Port which metrics should be scraped from
  prometheus.io/scrape: true # Set if metrics should be scraped from this pod
  prometheus.io/path: "/metrics" # Path which metrics should be scraped from
```

**Note: This solution works only to scrape metrics from one container within the pod**

### Create a new HTTP source in Sumo Logic.

To avoid [blacklisting](https://help.sumologic.com/Metrics/Understand_and_Manage_Metric_Volume/Blacklisted_Metrics_Sources) metrics should be distributed across multiple HTTP sources. You can create a new HTTP source using `values.yaml`:

```yaml
sumologic:
  # ...
  sources:
    # ...
    metrics:
      # ...
      my_source:
        name: my-source-name
```

This will create a new HTTP source with the name `my-source-name` in your Sumo Logic account.
All sources are created on the same Collector.

**This configuration doesn't modify or remove HTTP sources from your account.
If you rename a source in `values.yaml`, the new source will be added to your Sumo Logic account**

### Update Fluentd configuration

Next, you will need to update the Fluentd configuration to ensure Fluentd routes your custom metrics to the HTTP source you created in the previous step.
To do that, you should add an output to your values.yaml:

```yaml

fluentd:
  # ...
  metrics:
    # ...
    output:
      # ...
      my_source:  # It matches sumologic.sources.my_source
        tag: prometheus.metrics.YOUR_TAG  # tag used by Fluentd's match clausule
        id: sumologic.endpoint.metrics
      
      # alternative example source with all fields
      alternative_source:  # It doesn't match any source name
        tag: prometheus.metrics.YOUR_TAG**
        id: sumologic.endpoint.metrics
        source: my_source  # you can specify which source should be used (the output key (alternative_source) is taken by default)
        weight: 10  # optional, by default takes 0 and it is use to prioritise outputs (less means more important)
        drop: true  # Drop records which match the tag (false by default)
```

The weight concept helps to keep Fluentd outputs in the correct order.
In the above example, the `alternative_source` covers all tags for the `my_source`.
This means if `alternative_source` has less weight than `my_source`
it would process all records and none of them would be taken by `my_source`.

NOTE: [Explanation of Fluentd match order](https://docs.fluentd.org/configuration/config-file#note-on-match-order)

### Update the prometheus-overrides.yaml file to forward the metrics to Fluentd.

The configuration file controls what metrics get forwarded on to Sumo Logic. To send custom metrics to Sumo Logic you need to update it to include a rule to forward on your custom metrics. Make sure you include the same tag you created in your Fluentd configmap in the previous step. Here is an example addition to the configuration file that will forward metrics to Sumo:

```yaml
prometheus-operator:  # For values.yaml
    # ...
    prometheus:
      # ...
      prometheusSpec:
        # ...
        remoteWrite:
          # ...
          - url: http://$(CHART).$(NAMESPACE).svc.cluster.local:9888/prometheus.metrics.YOUR_TAG
            writeRelabelConfigs:
            - action: keep
              regex: <YOUR_CUSTOM_MATCHER>
              sourceLabels: [__name__]
```

According to our example, below config could be useful:

```yaml
prometheus-operator:  # For values.yaml
    # ...
    prometheus:
      # ...
      prometheusSpec:
        # ...
        remoteWrite:
          # ...
          - url: http://$(CHART).$(NAMESPACE).svc.cluster.local:9888/prometheus.metrics.YOUR_TAG
            writeRelabelConfigs:
            - action: keep
              regex: 'example-metrics'
              sourceLabels: [service]
```

Replace `YOUR_TAG` with a tag to identify these metrics. After adding this to the `yaml`, go ahead and upgrade your sumologic or prometheus operator installation, depending on method used:

* `helm upgrade collection sumologic/sumologic --reuse-values -f <path to values.yaml>` to upgrade sumologic collection
* `helm upgrade prometheus-operator stable/prometheus-operator --reuse-values -f <path to prometheus-overrides.yaml>` to upgrade your prometheus-operator.

Note: When executing the helm upgrade, to avoid the error below, you need to add the argument `--force`.

      invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/name":"kube-state-metrics"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable

If all goes well, you should now have your custom metrics piping into Sumo Logic.
