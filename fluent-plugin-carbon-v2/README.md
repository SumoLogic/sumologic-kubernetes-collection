# fluent-plugin-carbon-v2

[Fluentd](https://fluentd.org/) filter plugin to transform data point to carbon v2 format.

- Sample of Input

```json
{
    "endpoint": "http-metrics",
    "handler": "prometheus",
    "instance": "172.20.36.191:10251",
    "job": "kube-scheduler",
    "namespace": "kube-system",
    "kubernetes": {
        "pod": {
            "name": "kube-scheduler-ip-172-20-36-191.us-west-1.compute.internal"
        },
        "service": {
            "name": "kube-scheduler"
        }
    },
    "prometheus": "monitoring/prometheus-operator-prometheus",
    "prometheus_replica": "prometheus-prometheus-operator-prometheus-0",
    "service": "prometheus-operator-kube-scheduler",
    "@metric": "http_request_size_bytes_sum",
    "@timestamp": 1550862304339,
    "@value": 1619905.0
}
```

- Sample of Output

```json
{
    "message": "metric=http_request_size_bytes_sum _sourceType=kubernetes endpoint=http-metrics handler=prometheus instance=172.20.36.191:10251 job=kube-scheduler kubernetes.pod.name=kube-scheduler-ip-172-20-36-191.us-west-1.compute.internal kubernetes.service.name=kube-scheduler namespace=kube-system prometheus=monitoring/prometheus-operator-prometheus prometheus_replica=prometheus-prometheus-operator-prometheus-0 service=prometheus-operator-kube-scheduler   1619905.0 1550862304339"
}
```

## Installation

### RubyGems

```sh
gem install fluent-plugin-carbon-v2
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-carbon-v2"
```

And then execute:

```sh
bundle
```

## Configuration

### relabel (hash) (optional)

Relabel the field name in the input record.
For every (`key`, `value`) pairs in the hash, the field named with `key` in the input record will be relabeled to `value`.
If `key` is not a field in the input record, it will be ignored.
If `value` is an empty string, the field will be removed from the record.

Default value: `{}`.

### inclusions (hash) (optional)

White list of the records with regular expression matching on the field(s).
For __all__ (`key`, `value`) pairs in the hash, only following records will be included in the output:

- the value of field named with `key` matches the `value` (as regular expression).

Default value: `{}`.

### strict_inclusions (bool) (optional)

If `true`, records missing any field in keys of `inclusions` will be dropped.

Default value: `false`

### exclusions (hash) (optional)

Black list of the records with regular expression matching on the field(s).
For __any__ (`key`, `value`) pairs in the hash, following records will be excluded in the output:

- the value of field named with `key` matches the `value` (as regular expression).

Default value: `{}`.

### strict_exclusions (bool) (optional)

If `true`, records missing any field in keys of `exclusions` will be dropped.

Default value: `false`

__NOTE__ inclusions/exclusions rules are applied after relabeling and flatten