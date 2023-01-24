# kube-prometheus Mixin

If you are already using kube-prometheus, you can use the Prometheus installation from there and send metrics to Sumo Logic using a mixin to
add the correct remote_write configs and add the `cluster` external_label. You can generate mixin configuration using `kubectl` or `docker`:

```bash
 # using kubectl
 kubectl run tools \
  -it --quiet --rm \
  --restart=Never -n sumologic \
  --image sumologic/kubernetes-tools:2.13.0 \
  -- template-prometheus-mixin > kube-prometheus-sumo-logic-mixin.libsonnet

 # or using docker
 docker run -it --rm \
  sumologic/kubernetes-tools:2.13.0 \
  template-prometheus-mixin > kube-prometheus-sumo-logic-mixin.libsonnet
```

The defaults assume you're deploying Sumo Logic collection via Helm and using few customizations. When deploying collection, disable the
built-in Prometheus Operator by editing `values.yml`:

```yaml
kube-prometheus-stack:
  enabled: false
```

## Simple Example

```jsonnet
local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import 'kube-prometheus-sumo-logic-mixin.libsonnet') + // import the collection mixin
  {
    _config+:: {
      namespace: 'monitoring',
      clusterName: 'CLUSTER NAME HERE', // This value gets assigned the the cluster external_label in Prometheus
    },
  };

{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
```

## Non-default remote write url

If you aren't using the defaults, either by changing the namespace collection is deployed in or changing the service name, you'll have to do
edit `$._config.sumologicCollectorSvc` to point to the correct metadata enrichment service.

This service can be found under the `metadataMetrics` key in the `sumologic-configmap` ConfigMap.

```jsonnet
local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import 'kube-prometheus-sumo-logic-mixin.libsonnet') + // import the collection mixin
  {
    _config+:: {
      namespace: 'monitoring',
      clusterName: 'CLUSTER NAME HERE',

      // This should be the FQDN of the metadata enrichment service.
      sumologicCollectorSvc: 'http://collection-sumologic-remote-write-proxy.sumologic.svc.cluster.local.:9888/',
    },
  };

// ...
```
