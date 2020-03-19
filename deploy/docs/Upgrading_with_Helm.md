
# Upgrading with Helm

When a new version of a chart is released, or when you want to change the configuration of your release, you can use the `helm upgrade` command.

By default, any settings you set when you first installed will be overriden by the default configuration, since helm uses the default values.yaml unless you specify those configurations again (through either --set or -f values.yaml covered below). If you wish to preserve your current configuration (including the values for Sumo Logic API endpoint, Access ID, and Access Key) use `--reuse-values`.

If desired, there are two ways to pass configuration data when using `helm upgrade`:

- `--values` or `-f`: Specify a YAML file with overrides. This can be specified multiple times and the rightmost file will take precedence

- `--set` (and its variants `--set-string` and `--set-file`): Specify overrides on the command line.

**Note**:
- Assuming the default “collection” name is used, the following command can be used to get your current values.yaml file.

```
helm get values collection > current-values.yaml
```

- If no chart value arguments are provided on the command line, any existing customized values are carried forward, i.e. the `--reuse-values` flag will be used by default. If you want to revert to just the values provided in the chart, use the `-–reset-values` flag.

- If there exists `--set/--set-file/--set-string/--values/-f` , the `--reset-values` flag will be used by default.

- If you are using an [Alpha Release](./Alpha_Release_Guide.md) you will need to append `--version=X.X.X-alpha` to your `helm upgrade` command to avoid changing the version of the Helm chart installed. Use `helm ls` to find your current Helm chart version.

### Example to upgrade without any arguments:

```bash
helm upgrade collection sumologic/sumologic
```
In the above command, since no arguments were specified, the `--reuse-values` flag will be used by default.

**Always download the latest version of `values.yaml` from the following link and synchronize it based on your existing `values.yaml` file before running the upgrade.**

```bash
curl https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/v0.17.0/deploy/helm/sumologic/values.yaml
```

### Example to upgrade using the `--version` flag:

```bash
helm upgrade collection sumologic/sumologic --reuse-values --version=<RELEASE-VERSION> -f values.yaml
```

### Example to upgrade using the `--set` flag:

```bash
helm upgrade collection sumologic/sumologic --reuse-values --set key1=val1, key2=val2
```

### Example to upgrade using the `-f` flag :  

```bash
$ helm upgrade collection sumologic/sumologic --reuse-values -f override.yaml
```

**Tip**: Use `--reuse-values` flag to retain the values for Sumologic API Endpoint, Access ID and Key.  

Reference link to official Helm documentation:  https://helm.sh/docs/helm/#helm-upgrade

