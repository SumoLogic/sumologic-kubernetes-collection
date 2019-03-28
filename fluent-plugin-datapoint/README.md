# fluent-plugin-datapoint

[Fluentd](https://fluentd.org/) output plugin to transform one timeseries event into one or multiple data points.

- Sample of Input

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

- Sample of Output

```json
{
    "endpoint": "http-metrics",
    "handler": "prometheus",
    "instance": "172.20.36.191:10251",
    "job": "kube-scheduler",
    "namespace": "kube-system",
    "pod": "kube-scheduler-ip-172-20-36-191.us-west-1.compute.internal",
    "prometheus": "monitoring/prometheus-operator-prometheus",
    "prometheus_replica": "prometheus-prometheus-operator-prometheus-0",
    "service": "prometheus-operator-kube-scheduler",
    "@metric": "http_request_size_bytes_sum",
    "@timestamp": 1550862304339,
    "@value": 1619905.0
}
...
```

## Installation

### RubyGems

```sh
gem install fluent-plugin-datapoint
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-datapoint"
```

And then execute:

```sh
bundle
```

## Configuration

### tag (string) (optional)

Override the tag on output event stream. If not specify, will keep the tag on input.

### missing_values (float) (optional)

Override the `@value` in output for the samples without `value` field or `value` field equals `NaN`. If `missing_values` equals to `NaN` (default), these kind of samples will be dropped in output event stream.

Default value: `NaN`.
