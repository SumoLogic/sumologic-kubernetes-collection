# Traces

## Load balancing using the gateway

Open Telemetry supports Trace ID aware load balancing. An example use case for load balancing is scaling `cascading_filter` that requires
spans with same Trace ID to be send to the same collector instance.

Sumo Logic kubernetes collection supports three layer architecture - with an agent, gateway and a collector - in order to perform Trace ID
aware load balancing.

Agent, if the gateway is enabled, sends traces to the gateway. Gateway is configured with a load balancing exporter pointing to the
collector headless service. Gateway may also be exposed outside cluster, allowing to load balance traces originating from outside kubernetes
cluster.

Sample config:

```yaml
sumologic:
  traces:
    enabled: true

otelcolInstrumentation:
  enabled: true

tracesGateway:
  enabled: true
```

Refs:

- [Trace ID aware load balancing](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/loadbalancingexporter/README.md)
- [Using cascading_filter](https://help.sumologic.com/docs/apm/traces/advanced-configuration/filter-shape-tracing-data)
