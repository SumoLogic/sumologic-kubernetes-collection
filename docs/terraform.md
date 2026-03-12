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

You can add [Processing Rules](https://www.sumologic.com/help/docs/send-data/collection/processing-rules) to an HTTP source via
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

The configuration snippet below configures two [fields](https://www.sumologic.com/help/docs/manage/fields/), (`node` and `deployment`) for
the default logs source:

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

## Using Internal/Private Terraform Provider Registry

For air-gapped environments or organizations that require providers to be downloaded from internal registries, you can configure the Helm
chart to download Terraform providers from internal file servers (Nexus, Artifactory, S3, etc.) instead of the public Terraform Registry.

### Configuration

The setup job automatically detects and uses custom provider configuration if provided via `additionalFiles`. This approach downloads
provider binaries from direct file URLs before `terraform init` runs.

Add the following to your `values.yaml` or a custom values file:

```yaml
sumologic:
  setup:
    additionalFiles:
      terraform:
        # Pre-init script downloads providers before terraform init
        pre-init.sh: |
          #!/bin/bash
          set -e

          echo "Downloading Terraform providers..."

          # Create provider directory structure
          PROVIDER_DIR="/terraform/terraform-plugins/registry.terraform.io/sumologic/sumologic/3.0.0/linux_amd64"
          mkdir -p "$PROVIDER_DIR"

          # Download provider zip from your file server
          # Replace with your actual URL (Nexus raw repo, S3, etc.)
          wget -O /tmp/terraform-provider-sumologic.zip \
            "https://nexus.company.com/repository/terraform-files/terraform-provider-sumologic_3.0.0_linux_amd64.zip"

          # Extract the provider binary from the zip
          unzip -o /tmp/terraform-provider-sumologic.zip -d "$PROVIDER_DIR"

          # Make it executable
          chmod +x "$PROVIDER_DIR"/terraform-provider-sumologic_v*

          echo "✅ Provider downloaded successfully"

          # Cleanup
          rm /tmp/terraform-provider-sumologic.zip

        # Configure Terraform to use filesystem mirror
        terraformrc: |
          provider_installation {
            filesystem_mirror {
              path = "/terraform/terraform-plugins"
              include = ["registry.terraform.io/sumologic/*"]
            }
            direct {
              exclude = ["registry.terraform.io/sumologic/*"]
            }
          }
```

**How it works:**

- The `pre-init.sh` script downloads provider binaries from your file server before `terraform init` runs
- Terraform uses the `terraformrc` configuration to load providers from the local filesystem instead of the public registry
- Suitable for Nexus raw repositories, Artifactory, S3, or any HTTP file server
- The pre-init script runs automatically before Terraform initialization
- If the pre-init script fails (non-zero exit code), the setup job will fail immediately with a clear error message

**Important Notes:**

- Always include `set -e` at the start of your pre-init script to ensure any command failure causes the script to exit
- If provider download fails, the setup job will stop before running `terraform init`, preventing confusing error messages
- The example above downloads a `.zip` file and extracts it. Make sure your provider URL matches the actual file format
- The `terraform` directory under `additionalFiles` is **reserved** for Terraform provider configuration (pre-init.sh, terraformrc). It is
  processed early in the setup flow and skipped by the post-installation custom script runner. Use other directory names for custom
  post-installation scripts.

### Authentication

If your internal file server requires authentication, add credentials to the wget command in the pre-init script:

```bash
# Basic authentication
wget --user=username --password=password -O /tmp/terraform-provider-sumologic.zip \
  "https://nexus.company.com/repository/files/terraform-provider-sumologic_3.0.0_linux_amd64.zip"

# Or use token/header authentication
wget --header="Authorization: Bearer YOUR_TOKEN" -O /tmp/terraform-provider-sumologic.zip \
  "https://nexus.company.com/repository/files/terraform-provider-sumologic_3.0.0_linux_amd64.zip"
```

### Verification

When the setup job runs, you'll see the following in the logs if the custom configuration is detected:

```
====================================================================
Using custom Terraform CLI config: /customer-scripts/terraform_terraformrc
Providers will be downloaded from internal registry as configured.
====================================================================
Initializing provider plugins...
- Finding sumologic/sumologic versions matching ">= 3.0.0, < 3.1.5"...
- Installing sumologic/sumologic v3.0.0...
```

Monitor the logs to ensure providers are being downloaded from your internal registry.

### Additional Resources

- [Terraform CLI Configuration](https://developer.hashicorp.com/terraform/cli/config/config-file)
- [Filesystem Mirror Configuration](https://developer.hashicorp.com/terraform/cli/config/config-file#filesystem_mirror)
- [Sumo Logic Provider Releases](https://github.com/SumoLogic/terraform-provider-sumologic/releases)
