# fluent-plugin-protobuf

[Fluentd](https://fluentd.org/) parser plugin to transform [Prometheus](https://prometheus.io/) metrics from compressed, protobuf format into a timeseries event.

- Sample of output

```json
{
    "timeseries": [
        {
            "labels": [
                {
                    "name": "__name__",
                    "value": "http_request_size_bytes_sum"
                },
                {
                    "name": "endpoint",
                    "value": "http-metrics"
                },
                {
                    "name": "handler",
                    "value": "prometheus"
                },
                {
                    "name": "instance",
                    "value": "172.20.36.191:10251"
                },
                {
                    "name": "job",
                    "value": "kube-scheduler"
                },
                {
                    "name": "namespace",
                    "value": "kube-system"
                },
                {
                    "name": "pod",
                    "value": "kube-scheduler-ip-172-20-36-191.us-west-1.compute.internal"
                },
                {
                    "name": "prometheus",
                    "value": "monitoring/prometheus-operator-prometheus"
                },
                {
                    "name": "prometheus_replica",
                    "value": "prometheus-prometheus-operator-prometheus-0"
                },
                {
                    "name": "service",
                    "value": "prometheus-operator-kube-scheduler"
                },
                ...
            ],
            "samples": [
                {
                    "value": 1619905,
                    "timestamp": 1550862304339
                },
                ...
            ]
        },
        ...
    ]
}
```

## Installation

### RubyGems

```sh
gem install fluent-plugin-protobuf
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-protobuf"
```

And then execute:

```sh
bundle
```
