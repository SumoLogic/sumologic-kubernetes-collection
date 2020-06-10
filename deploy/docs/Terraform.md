# Terraform

Terraform is used by sumologic-kubernetes-collection during the setup process
to automatically create HTTP sources and store their URLs in the Kubernetes secret.

We are using two providers to perform those actions:
 * [Kubernetes Terraform provider](https://www.terraform.io/docs/providers/kubernetes/)
 * [Sumo Logic Terraform provider](https://www.terraform.io/docs/providers/sumologic/)

## Kubernetes Terraform provider

[Kubernetes Terraform provider](https://www.terraform.io/docs/providers/kubernetes/) is responsible for creating the secret with the created HTTP source endpoints during setup process. The default configuration is expected to work in most cases, however, for self-hosted kubernetes clusters there can be a few exceptions. For these cases we expose the provider configuration in `values.yaml`.

```yaml
sumologic:
  # Configuration of kubernetes for terraform client
  # https://www.terraform.io/docs/providers/kubernetes/index.html#argument-reference
  # All double quotes should be escaped here regarding terraform syntax
  cluster:
    host: "https://kubernetes.default.svc"
    # username:
    # password:
    # insecure:
    # client_certificate:
    # client_key:
    cluster_ca_certificate: "${file(\"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt\")}"
    # config_path:
    # config_context:
    # config_context_auth_info:
    # config_context_cluster:
    token: "${file(\"/var/run/secrets/kubernetes.io/serviceaccount/token\")}"
    load_config_file: false
    # exec:
    #   api_version:
    #   command:
    #   args: []
    #   env: {}
```

**Note** [Documentation for Kubernetes provider](https://www.terraform.io/docs/providers/kubernetes/index.html)

## Sumo Logic Terraform provider

The [Sumo Logic Terraform provider](https://www.terraform.io/docs/providers/sumologic/) creates your HTTP sources.
The related configuration section in the `values.yaml` file is under `sumologic.sources`:

```yaml
sumologic:
  # ...
  sources:
    # ...
    logs: # can be one of: logs/metrics/events/traces
      example-source: # source reference name
        name: # name of the source (visible on the sumologic platform)
        config-name: # name which be used in secret to store the url. This is backward-compatibility option
        category: # this is backward compatibility property.
                  # Sets source category to "${var.cluster_name}/${local.default_events_source}" if true
                  # To overwrite category, please use `sumologic.sources[].properties.category`
        properties: # Additional terraform properties like fields or content_type
                    # ref: https://www.terraform.io/docs/providers/sumologic/r/collector.html
```

### Properties

You can set all of the source [properties](https://www.terraform.io/docs/providers/sumologic/r/http_source.html#argument-reference)
using `sumologic.sources.<logs,traces,metrics,traces>.<source ref name>.properties`.

#### Fields

The configuration snippet below configures two [fields](https://help.sumologic.com/Manage/Fields), (`node` and `deployment`) for the default logs source:

```yaml
sumologic:
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

**Note** You have to manually activate fields using the Sumo Logic service.
