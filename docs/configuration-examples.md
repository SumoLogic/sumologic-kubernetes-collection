# Configuration examples

This document contains examples of configuration for the Helm Chart.

## Minimal configuration

An example file with the minimum configuration is provided below.

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
```

## OpenShift with limiting the scope of the interaction of our Prometheus Operator

An example configuration for Openshift which install our Prometheus Operator side by side with an existing one:

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
  scc:
    create: true
kube-prometheus-stack:
  prometheusOperator:
    namespaces:
      additional:
        - my-namespace
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
otellogs:
  daemonset:
    containers:
      otelcol:
        securityContext:
          privileged: true
    initContainers:
      changeowner:
        securityContext:
          privileged: true
tailing-sidecar-operator:
  scc:
    create: true
```

## OpenShift using existing Prometheus Operator which is by default available in `openshift-monitoring` namespace

An example configuration for OpenShift which uses existing Prometheus Operator:

```yaml
sumologic:
  accessId: ${SUMO_ACCESS_ID}
  accessKey: ${SUMO_ACCESS_KEY}
  clusterName: ${MY_CLUSTER_NAME}
  scc:
    create: true
kube-prometheus-stack:
  prometheus-node-exporter:
    service:
      port: 9200
      targetPort: 9200
  prometheusOperator:
    enabled: false
otellogs:
  daemonset:
    containers:
      otelcol:
        securityContext:
          privileged: true
    initContainers:
      changeowner:
        securityContext:
          privileged: true
tailing-sidecar-operator:
  scc:
    create: true
```

**NOTE:** Please refer to
[Using existing Operator to create Sumo Logic Prometheus instance](/docs/prometheus.md#using-existing-operator-to-create-sumo-logic-prometheus-instance)
before applying the configuration.
