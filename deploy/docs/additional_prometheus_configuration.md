# Additional Prometheus Configuration

## Filter metrics

The `prometheus-overrides.yaml` file specifies metrics to be collected. If you want to exclude some metrics from collection, or include others, you can edit `prometheus-overrides.yaml`. The file contains a section like the following for each of the Kubernetes components that report metrics in this solution: API server, Controller Manager, and so on.

If you would like to collect other metrics that are not listed in `prometheus-overrides.yaml`, you can add a new section to the file.

```yaml
    - url: http://fluentd:9888/prometheus.metrics.<some_label>
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

Service Monitors is how we tell Prometheus what endpoints and sources to pull metrics from. To define a Service Monitor, create a yaml file on disk with information templated as follows:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  labels:
    team: frontend
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: web
  ```

Replace the `name` with a name that relates to your service, and a `matchLabels` that would match the pods you want this service monitor to scrape against. By default, prometheus attempts to scrape metrics off of the `/metrics` endpoint, but if you do need to use a different url, you can override it by providing a `path` attribute in the settings like so:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: prometheus-operator-kubelet
  name: prometheus-operator-kubelet
  namespace: sumologic
  release: prometheus-operator
spec:
  endpoints:
  - path: /metrics/cadvisor
    port: https-metrics
...
```

Note, you need to ensure the `release` label matches the `release` label on your Prometheus pod.

Detailed instructions on service monitors can be found via [Prometheus-Operator](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources) website.
Once you have created this yaml file, go ahead and run `kubectl create -f name_of_yaml.yaml -n sumologic`. This will create the service monitor in the sumologic namespace.

### Create a new HTTP source in Sumo Logic.

To avoid [blacklisting](https://help.sumologic.com/Metrics/Understand_and_Manage_Metric_Volume/Blacklisted_Metrics_Sources) metrics should be distributed across multiple HTTP sources. You can [follow these steps](https://help.sumologic.com/03Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source) to create a new HTTP source for your custom metrics. Make note of the URL as you will need it in the next step.

### Update the metrics.conf Fluentd Configuration

Next, you will need to update the Fluentd configuration to ensure Fluentd routes your custom metrics to the HTTP source you created in the previous step.

  * First, base64 encode the HTTP source URL from the previous step by running `echo <HTTP_SOURCE_URL> | base64`.  Replace `<HTTP_SOURCE_URL>` with the URL from step 3.
  * Next, you can edit the secret that houses all the HTTP sources URLs. Assuming you installed the collector in the  `sumologic` namespace, you can run `kubectl -n sumologic edit secret sumologic` or edit the YAML you deployed when you set up collection.
  * In the `data` section, add a new key and the base64 encoded value you created. The following is just a snippet of the secret for an example. Do not alter the existing content, you simply want to add a new key.
  
```yaml
data:
...
my-custom-metrics: <base64EncodedURL>
kind: Secret
```

  * Next you need to edit the Fluentd Deployment and add a new environment variable, pointing to the new secret.  Assuming you installed the collector in the  `sumologic` namespace, you can run `kubectl -n sumologic edit deployment fluentd` or edit the YAML you deployed when you set up collection. Note, if you installed using helm, the name of the deployment may be different depending on how you installed the helm chart.
  * Locate the `SUMO_ENDPOINT_LOGS` environment variable in the YAML and add a new environment variable that points to the secret key you created. The following is an example.
  
```yaml
...
        - name: SUMO_ENDPOINT_LOGS
          valueFrom:
            secretKeyRef:
              key: endpoint-logs
              name: sumologic
        - name: MY_CUSTOM_METRICS
          valueFrom:
            secretKeyRef:
              key: my-custom-metrics
              name: sumologic
        - name: LOG_FORMAT
          value: fields
```

  * Finally, you need to modify the Fluentd config to route data to your newly created HTTP source. Assuming you installed the collector in the `sumologic` namespace, you can run `kubectl -n sumologic edit configmap fluentd` or edit the YAML you deployed when you set up collection. Note, if you installed using helm, the name of the deployment may be different depending on how you installed the helm chart.
  * Locate the section `match prometheus.metrics` and you will insert a new section above this. The `match` statement should end with a tag that identifies your data that Fluentd will use for routing. Then make sure you point to the environment variable you added to your deployment. The following is an example.
  
```yaml
...        
          <match prometheus.metrics.YOUR_TAG>
             @type sumologic
             @id sumologic.endpoint.metrics
             endpoint "#{ENV['MY_CUSTOM_METRICS']}"
             @include metrics.output.conf
           </match>
          <match prometheus.metrics**>
             @type sumologic
             @id sumologic.endpoint.metrics
             endpoint "#{ENV['SUMO_ENDPOINT_METRICS']}"
             @include metrics.output.conf
           </match>
```

### Update the prometheus-overrides.yaml file to forward the metrics to Fluentd.

The `prometheus-overrides.yaml` file controls what metrics get forwarded on to Sumo Logic. To send custom metrics to Sumo Logic you need to update the `prometheus-overrides.yaml` file to include a rule to forward on your custom metrics. Make sure you include the same tag you created in your Fluentd configmap in the previous step. Here is an example addition to the `prometheus-overrides.yaml` file that will forward metrics to Sumo:

```
- url: http://collection-sumologic.sumologic.svc.cluster.local:9888/prometheus.metrics.YOUR_TAG
      writeRelabelConfigs:
      - action: keep
        regex: <YOUR_CUSTOM_MATCHER>
        sourceLabels: [__name__]
```

Replace `YOUR_TAG` with a tag to identify these metrics. After adding this to the `yaml`, go ahead and run a `helm upgrade prometheus-operator stable/prometheus-operator -f prometheus-overrides.yaml` to upgrade your `prometheus-operator`.

Note: When executing the helm upgrade, to avoid the error below, you need to add the argument `--force`.

      invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/name":"kube-state-metrics"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable

If all goes well, you should now have your custom metrics piping into Sumo Logic.
