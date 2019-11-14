# fluent-plugin-events

Use the [Fluentd](https://fluentd.org/) input plugin to watch Kubernetes events from the Kubernetes API Server.

### Events

To customize fields for events edit the provided (`fluentd-sumologic.yaml`) file by specifying the fields in the `events` plugin `@type` parameter. The following example has specified the `type_selector`, `deploy_namespace`, and `configmap_update_interval_seconds` fields,

```json
<source>
    @type events
    deploy_namespace sumologic
    type_selector ["ADDED", "MODIFIED", "DELETED"]
    configmap_update_interval_seconds 5
</source>
```

#### Configurable fields for events

Parameter Name | Default |Description |
------------ | ------------- | -------------
resource_name | "events" | Collect events for a specific resource type, such as pods, deployments, or services.
api_version | v1 | Version of the Kubernetes Events API.
tag | "kubernetes.*" | Tag collected events.
namespace | nil | Collect events from a specific namespace.
label_selector | nil | Collect events for resources matching a specific label.
field_selector | nil | Collect events for resources matching a specific field.
type_selector | ["ADDED", "MODIFIED"] | Collect specific event types. Currently supports "ADDED", "MODIFIED", and "DELETED".
configmap_update_interval_seconds | 10 | Resource version is used to resume events collection from where it left off after a container/pod/node restart. The latest resource version of your events is kept in memory and backed up to a ConfigMap at an interval. By default, we back up the resource version by making a ConfigMap API call every 10 seconds. If you want to back up more frequently, reduce the interval. If you want to reduce the number of API calls, increase the interval.
watch_interval_seconds | 300 | Interval at which the watch thread gets recreated.
deploy_namespace | "sumologic" | Namespace that the events plugin resources will be created in. 
kubernetes_url | nil | URL of the Kubernetes API.
client_cert | nil | Path to the certificate file for the client.
client_key | nil | Path to the private key file for the client.
ca_file | nil | Path to the CA file.
secret_dir | "/var/run/secrets/kubernetes.io/serviceaccount" | Path of the location where the service account credentials for the pod are stored.
bearer_token_file | nil | Path to the file containing the API token. By default it reads from the file "token" in the `secret_dir`.
verify_ssl | true | Whether to verify the API server certificate.
ssl_partial_chain | false | If `ca_file` is for an intermediate CA, or otherwise we do not have the root CA and want to trust the intermediate CA certs we do have, set this to `true` - this corresponds to the openssl s_client -partial_chain flag and X509_V_FLAG_PARTIAL_CHAIN

## Installation

### RubyGems

```
$ gem install fluent-plugin-events
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-events"
```

And then execute:

```
$ bundle
```
