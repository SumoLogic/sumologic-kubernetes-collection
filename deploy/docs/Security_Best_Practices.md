# Advanced Configuration / Security Best Practices

- [Hardening fluentd StatefulSet with `securityContext`](#hardening-fluentd-statefulset-with-securitycontext)

## Minimal required capabilities

This section explains the basic requirements for the collection solution in terms of network and security policies.
It is intended to serve as a guide for running collection in highly locked-down environments.

Pipelines for the three different data types collection supports - logs, metrics and traces - are completely
independent in this respect, so we're going to discuss each one separately. If a particular data type is
not enabled in the configuration, there is no need to do anything, as the respective components will
simply not be started.

Logically, the pipeline for a data type is composed of the following components

```
Collector -> Metadata Enrichment -> Sumologic Backend
```

Different applications may serve the same role here - for example, FluentD is currently used for metadata enrichment
for both logs and metrics, but the plan is to replace it with the Opentelemetry Collector in the near future. Nonetheless,
the required capabilities are only based on the role, not the specific application.

### Logs

Log collection is done by a node agent, which reads them directly from the node by having the right directories
\- `/var/log/containers` for container logs and `/var/log/journal` for journald logs - mounted as volumes in the
agent container. In order to read them, the agent container needs to run as a user with the right permissions.

As Kubernetes distributions have different ACLs set for these directories, Fluent-Bit runs as the root user by default
for maximum out-of-the-box compatibility. This can be set to any user or group id with permission to read log files
in the aforementioned directories on the node. In terms of collection configuration, the value to modify is
`fluent-bit.securityContext` for Fluent-Bit.

The log collector needs to be able to talk to the log metadata enrichment service. It does not need to do any other
requests over the network.

The log metadata enrichment service needs to be able to talk to the Sumo Logic backend receiver endpoints. It also needs
to be able to access the Kubernetes API Server to obtain metadata.

Example Kubernetes Network Policies restricting all but the necessary traffic for the logs pipeline:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: fluent-bit
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: fluent-bit
  policyTypes:
  - Ingress
  - Egress
  egress:
  # send logs to FluentD
  - to:
    - podSelector:
        matchLabels:
          app: <release_name>-sumologic-fluentd-logs
    ports:
    - protocol: TCP
      port: 24321
  ingress:
  # Allow Prometheus to scrape metrics
  - from:
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 2020
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: fluentd-logs
spec:
  podSelector:
    matchLabels:
      app: <release_name>-sumologic-fluentd-logs
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # allow logs from Fluent-Bit
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: fluent-bit
    ports:
    - protocol: TCP
      port: 24321
  # Allow Prometheus to scrape metrics
  - from:
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 24321
  egress:
  # Allow all outbound connections
  - {}
```

### Metrics

Metrics collection is done via the Prometheus protocol, which means that the metrics collector needs to be able to
reach any service it needs to collect metadata from over the network. This includes the metrics enrichment service.

The metrics metadata enrichment service needs to be able to talk to the Sumo Logic backend receiver endpoints. It also needs
to be able to access the Kubernetes API Server to obtain metadata.

Example Kubernetes Network Policies restricting all but the necessary traffic for the traces pipeline:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus
  namespace: sumologic
spec:
  podSelector:
    matchLabels:
      app: prometheus
  policyTypes:
  - Egress
  - Ingress
  ingress:
    # Allow Prometheus to scrape metrics
  - from:
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 9090
  egress:
  # remote write to FluentD
  - to:
    - podSelector:
        matchLabels:
          app: <release_name>-sumologic-fluentd-metrics
    ports:
    - protocol: TCP
      port: 9888
  # scrape metrics
  - ports:
    - protocol: TCP
      port: 2379
      endPort: 24321
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: fluentd-metrics
  namespace: sumologic
spec:
  podSelector:
    matchLabels:
      app: collection-sumologic-fluentd-metrics
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow data from Prometheus remote write
  - from:
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 9888
  # Allow Prometheus to scrape metrics
  - from:
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 24321
  egress:
  # Allow all outbound connections
  - {}
```

The above configuration is very permissive for Prometheus egress. You're encouraged to make it more restrictive based
on your specific requirements.

### Tracing

Traces are sent to the collector by applications themselves, so any application needing to publish traces needs to
be able to reach the collector over the network.

The tracing collector and metadata enrichment are currently done by the same service. As such, this service needs to
be able to talk to the Sumo Logic backend receiver endpoints, and the Kubernetes API Server.

Example Kubernetes Network Policies restricting all but the necessary traffic for the traces pipeline:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: otelcol
spec:
  podSelector:
    matchLabels:
      app: <release_name>-sumologic-otelcol
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow inbound traffic on all the receiver ports
  - ports:
    - protocol: TCP
      port: 4317
    - protocol: TCP
      port: 5778
    - protocol: TCP
      port: 6831
    - protocol: TCP
      port: 6832
    - protocol: TCP
      port: 9411
    - protocol: TCP
      port: 14268
    - protocol: TCP
      port: 55678
    - protocol: TCP
      port: 55680
    - protocol: TCP
      port: 55681
  egress:
  # Allow all outbound connections
  - {}
```

You should only leave the ports for the protocol you're actually using to deliver spans to the receiver in the above definition. As with Prometheus,
the above configuration is very permissive for ingress. You're encouraged to make it more restrictive based on your specific requirements.

## Hardening fluentd StatefulSet with `securityContext`

One can use `fluentd.securityContext` and
`fluentd.(logs|metrics|events).statefulset.containers.fluentd.securityContext`
to tighten up the security requirements for fluentd containers running as part
of collection StatefulSets.

One example of such a configuration can be found below:

```yaml
fluentd:
  ...
  securityContext:
    ## The group ID of all processes in the statefulset containers.
    ## By default this needs to be fluent(999).
    fsGroup: 999
    runAsNonRoot: true
  logs:
    enabled: true
    ...
    statefulset:
      containers:
        fluentd:
          securityContext:
            runAsNonRoot: true
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
    extraVolumeMounts:
      - mountPath: /tmp/
        name: tmp-volume-logs
    extraVolumes:
      - emptyDir: {}
        name: tmp-volume-logs
  metrics:
    ...
```
