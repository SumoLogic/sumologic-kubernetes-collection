# Advanced Configuration / Security Best Practices

- [Hardening OpenTelemetry Collector StatefulSet with `securityContext`](#hardening-opentelemetry-collector-statefulsets-with-securitycontext)
- [FIPS compliant binaries](#fips-compliant-binaries)

## Minimal required capabilities

This section explains the basic requirements for the collection solution in terms of network and security policies. It is intended to serve
as a guide for running collection in highly locked-down environments.

Pipelines for the three different data types collection supports - logs, metrics and traces - are completely independent in this respect, so
we're going to discuss each one separately. If a particular data type is not enabled in the configuration, there is no need to do anything,
as the respective components will simply not be started.

Logically, the pipeline for a data type is composed of the following components

```
Collector -> Metadata Enrichment -> Sumologic Backend
```

Different applications may serve the same role here - for example, OpenTelemetry Collector is currently used for metadata enrichment for
both logs and metrics, but it used to be Fluentd in v2 of the Chart. Nonetheless, the required capabilities are only based on the role, not
the specific application.

### Logs

Log collection is done by a node agent, which reads them directly from the node by having the right directories \- `/var/log/containers` for
container logs and `/var/log/journal` for journald logs - mounted as volumes in the agent container. In order to read them, the agent
container needs to run as a user with the right permissions.

As Kubernetes distributions have different ACLs set for these directories, the log collector runs as the root user by default for maximum
out-of-the-box compatibility. This can be set to any user or group id with permission to read log files in the aforementioned directories on
the node. In terms of collection configuration, the value to modify is `otellogs.daemonset.securityContext` for the log collector.

The log collector needs to be able to talk to the log metadata enrichment service. It does not need to do any other requests over the
network.

The log metadata enrichment service needs to be able to talk to the Sumo Logic backend receiver endpoints. It also needs to be able to
access the Kubernetes API Server to obtain metadata.

Example Kubernetes Network Policies restricting all but the necessary traffic for the logs pipeline:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: otellogs
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: <release_name>-sumologic-otelcol-logs-collector
  policyTypes:
    - Ingress
    - Egress
  egress:
    # send logs to OpenTelemetry Collector
    - to:
        - podSelector:
            matchLabels:
              app: <release_name>-sumologic-otelcol-logs
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
  name: logs-metadata
spec:
  podSelector:
    matchLabels:
      app: <release_name>-sumologic-otelcol-logs
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # allow logs from log collector
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: <release_name>-sumologic-otelcol-logs-collector
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

Metrics collection is done via the Prometheus protocol, which means that the metrics collector needs to be able to reach any service it
needs to collect metadata from over the network. This includes the metrics enrichment service.

The metrics metadata enrichment service needs to be able to talk to the Sumo Logic backend receiver endpoints. It also needs to be able to
access the Kubernetes API Server to obtain metadata.

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
    # remote write to OpenTelemetry Collector
    - to:
        - podSelector:
            matchLabels:
              app: <release_name>-sumologic-otelcol-metrics
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
  name: metrics-metadata
  namespace: sumologic
spec:
  podSelector:
    matchLabels:
      app: collection-sumologic-otelcol-metrics
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

The above configuration is very permissive for Prometheus egress. You're encouraged to make it more restrictive based on your specific
requirements.

### Tracing

Traces are sent to the collector by applications themselves, so any application needing to publish traces needs to be able to reach the
collector over the network.

The tracing collector and metadata enrichment are currently done by the same service. As such, this service needs to be able to talk to the
Sumo Logic backend receiver endpoints, and the Kubernetes API Server.

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

You should only leave the ports for the protocol you're actually using to deliver spans to the receiver in the above definition. As with
Prometheus, the above configuration is very permissive for ingress. You're encouraged to make it more restrictive based on your specific
requirements.

## Hardening OpenTelemetry Collector StatefulSets with `securityContext`

You can use the following properties to set Pod Security Contexts:

- `metadata.securityContext`
- `otelevents.statefulset.securityContext`
- `otellogs.daemonset.securityContext`

These sections also contain settings to alter the contexts of specific containters.

One example of such a configuration can be found below:

```yaml
metadata:
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
        otelcol:
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

## Using a custom root CA for TLS interception

Unfortunately, there isn't a uniform way of adding root certificates to application containers. Generally speaking, this can be done in two
ways:

- At container image build time, making use of the underlying OS certificate management facilities
- At Pod start time, using `initContainers` and `extraVolumes`, also making use of the underlying OS certificate management facilities

### Adding a custom root CA certificate by rebuilding container images

Adding certificates during container build using the underlying Linux distribution's management facilities tends to be straightforward.
There are three different base distributions among container images used by the collection Helm Chart: `debian`, `alpine` and `scratch`.

For Debian and Alpine Linux, please consult the documentation of these distributions. For example, assuming `cert.pem` is the certificate
file, the following suffices for Alpine Linux and `scratch`:

```Dockerfile
COPY cert.pem /usr/local/share/ca-certificates/cert.crt
RUN cat /usr/local/share/ca-certificates/cert.crt >> /etc/ssl/certs/ca-certificates.crt
```

Keep in mind that this needs to be done as the root user, and then the user should be switched back to the original image's default.

### Adding a custom root CA certificate using `initContainers`

It's customary for Helm Charts to allow customizing a Pod's `initContainers` and Volumes, in part to allow changes like this one. In effect,
what we do here is identical to what we'd do at build time, but it takes place during Pod initialization instead.

Here's an example configuration of a root certificate being added to a OpenTelemetry Collector StatefulSet this way. This assumes the
certificate is contained in the `root-ca-cert` Secret, under the `cert.pem` key:

```yaml
metadata:
  metrics:
    statefulset:
      initContainers:
        - name: update-certificates
          image: odise/busybox-curl
          command:
            - sh
            - -c
            - |
              cp /etc/ssl/certs/ca-certificates.crt /certs/ca-certificates.crt
              cat /root/ca-cert/cert.pem >> /certs/ca-certificates.crt
          volumeMounts:
            - name: root-ca-cert
              mountPath: /root/ca-cert/
              readOnly: true
            - name: certs
              mountPath: /certs/
              readOnly: true

    extraVolumes:
      - name: root-ca-cert
        secret:
          secretName: root-ca-cert
      - name: certs
        emptyDir: {}
    extraVolumeMounts:
      - name: certs
        mountPath: /etc/ssl/certs/
        readOnly: true
```

Note that if you embed all the necessary certificates in the Secret, you can skip copying them from the `curl-busybox` image in the example
and just mount the Secret directly to `/etc/ssl/certs/`. In that case, we can skip the `initContainers`:

```yaml
metadata:
  metrics:
    extraVolumes:
      - name: certs
        secret:
          secretName: root-ca-cert
    extraVolumeMounts:
      - name: certs
        mountPath: /etc/ssl/certs/
        readOnly: true
```

## FIPS compliant binaries

We provide FIPS compliant **OpenTelemetry Collector** binaries for your data collection and enrichment.

You can find them in our [ECR Public Gallery](https://gallery.ecr.aws/sumologic/sumologic-otel-collector). FIPS compliant image tags end
with `-fips`.

### Helm Chart v3

Starting with Helm Chart v3 **OpenTelemetry Collector** is a default method of collecting data (except for Prometheus) but still you need
set the FIPS compliant images.

To automatically use FIPS-compliant images for all components, set:

```yaml
sumologic:
  otelcolImage:
    addFipsSuffix: true
```

> **Note** This only adds a `-fips` suffix to the image tag. If you're customizing the tag and repository (for example by using a custom
> registry), please make sure to preserve this naming convention if you want to use this feature.

### Helm Chart v2

For Helm Chart v2 please
[see here how to switch to OpenTelemetry Collector](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/opentelemetry_collector.md).

When you use **OpenTelemetry Collector** you need set the fips compliant images.

For example, to use `0.76.1-sumo-0-fips` image with Helm Chart v2 use the following configuration:

```yaml
metadata:
  image:
    tag: 0.76.1-sumo-0-fips
otellogs:
  image:
    tag: 0.76.1-sumo-0-fips
otelevents:
  image:
    tag: 0.76.1-sumo-0-fips
otelcol:
  deployment:
    image:
      tag: 0.76.1-sumo-0-fips
otelagent:
  daemonset:
    image:
      tag: 0.76.1-sumo-0-fips
otelgateway:
  deployment:
    image:
      tag: 0.76.1-sumo-0-fips
```

### FIPS compliant images for Fluent Bit and Fluentd

This Helm Chart does not provide FIPS compliant binaries for **Fluent Bit** nor **Fluentd**.

### Troubleshooting

#### OpenTelemetry: dial tcp: lookup collection-sumologic-metadata-logs.sumologic.svc.cluster.local.: device or resource busy

Refer to
[Troubleshooting Collection document](/docs/troubleshoot-collection.md#opentelemetry-dial-tcp-lookup-collection-sumologic-metadata-logssumologicsvcclusterlocal-device-or-resource-busy).
