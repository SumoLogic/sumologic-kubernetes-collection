# Terraform

Terraform is used by sumologic-kubernetes-collection during the setup process to automatically create HTTP sources and store their URLs in
the Kubernetes secret.

We are using two providers to perform those actions:

- [Kubernetes Terraform provider](https://www.terraform.io/docs/providers/kubernetes/)
- [Sumo Logic Terraform provider](https://www.terraform.io/docs/providers/sumologic/)

## Kubernetes Terraform provider

[Kubernetes Terraform provider](https://www.terraform.io/docs/providers/kubernetes/) is responsible for creating the secret with the created
HTTP source endpoints during setup process. The default configuration is expected to work in most cases, however, for self-hosted Kubernetes
clusters there can be a few exceptions. For these cases we expose the provider configuration in `values.yaml`.

```yaml
sumologic:
  # Configuration of Kubernetes for Terraform client
  # https://www.terraform.io/docs/providers/kubernetes/index.html#argument-reference
  # All double quotes should be escaped here regarding Terraform syntax
  cluster:
    host: "https://kubernetes.default.svc"
    # username:
    # password:
    # insecure:
    # client_certificate:
    # client_key:
    cluster_ca_certificate: '${file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")}'
    # config_path:
    # config_context:
    # config_context_auth_info:
    # config_context_cluster:
    token: '${file("/var/run/secrets/kubernetes.io/serviceaccount/token")}'
    # exec:
    #   api_version:
    #   command:
    #   args: []
    #   env: {}
```

**Note** [Documentation for Kubernetes provider](https://www.terraform.io/docs/providers/kubernetes/index.html)

## Sumo Logic Terraform provider

The [Sumo Logic Terraform provider](https://www.terraform.io/docs/providers/sumologic/) creates your HTTP sources. The related configuration
section in the `values.yaml` file is under `sumologic.collector.sources`:

```yaml
sumologic:
  # ...
  collector:
    # ...
    sources:
      # ...
      logs: # source type, can be one of: logs/metrics/events/traces
        example-source: # source reference name
          name: # name of the source (visible on the sumologic platform)
          config-name: # name which be used in secret to store the url. This is backward-compatibility option
          category:# this is backward compatibility property. It's deprecated and it's going to be removed in version 2.0
            # Sets source category to "${var.cluster_name}/${local.default_events_source}" if true
            # To overwrite category, please use `sumologic.collector.sources[].properties.category`
          properties:# Additional Terraform properties like fields or content_type
            # ref: https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/http_source#argument-reference
```

### Usage

Source endpoints are exposed in the metadata enrichment service as environmental variables. The variable name is built using the schema
`SUMO_ENDPOINT_<source name>_<source type>_SOURCE`, where `<source name>` and `<source type>` are in uppercase and dashes are replaced with
underscores.

Examples:

- `sumologic.collector.sources.logs.example-source` becomes `SUMO_ENDPOINT_EXAMPLE_SOURCE_LOGS_SOURCE`
- `sumologic.collector.sources.traces.default` becomes `SUMO_ENDPOINT_DEFAULT_TRACES_SOURCE`

### Properties

You can set all of the source
[properties](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/http_source#argument-reference) using
`sumologic.collector.sources.<events,logs,metrics,traces>.<source ref name>.properties`.

#### Processing Rules

You can add [Processing Rules](https://help.sumologic.com/docs/send-data/collection/processing-rules) to an HTTP source via
`user-values.yaml`. Below is an example of an exclude rule to filter `DEBUG` log messages. All logs from Kubernetes (Systemd, container, and
custom logs) will have this filter applied.

```yaml
sumologic:
  # ...
  collector:
    # ...
    sources:
      # ...
      logs:
        # ...
        default:
          # ...
          name: logs
          config-name: endpoint-logs
          properties:
            filters:
              - name: "Test Exclude Debug"
                filter_type: "Exclude"
                regexp: ".*DEBUG.*"
```

#### Fields

The configuration snippet below configures two [fields](https://help.sumologic.com/docs/manage/fields/), (`node` and `deployment`) for the
default logs source:

```yaml
sumologic:
  # ...
  collector:
    # ...
    sources:
      # ...
      logs:
        # ...
        default:
          # ...
          properties:
            fields:
              node: hornetq-livestream-9
              deployment: sumologic
```

#### Terraform variables

You can use Terraform extrapolation for properties:

```yaml
sumologic:
  collector:
    sources:
      logs:
        example-source:
          properties:
            category: "${var.cluster_name}/my-name"
```

List of available variables:

- `var.cluster_name`
- `var.namespace_name`
- `var.collector_name`

**Note** You have to manually activate fields using the Sumo Logic service.
