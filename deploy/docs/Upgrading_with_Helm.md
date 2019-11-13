
# Upgrading with Helm

When a new version of a chart is released, or when you want to change the configuration of your release, you can use the helm upgrade command.

If desired, there are two ways to pass configuration data:

- `--values` or `-f`: Specify a YAML file with overrides. This can be specified multiple times and the rightmost file will take precedence

- `--set` (and its variants `--set-string` and `--set-file`): Specify overrides on the command line.


**Note**:
- To edit or append to the existing customized values, add the `–reuse-values` flag, otherwise any existing customized values are ignored.

- If no chart value arguments are provided on the command line, any existing customized values are carried forward, i.e. the `--reuse-values` flag will be used by default. If you want to revert to just the values provided in the chart, use the `-–reset-values` flag.

- If there exists `--set/--set-file/--set-string/--values/-f` , the `--reset-values` flag will be used by default.

### Example to Upgrade without any arguments:

```bash
helm upgrade collection sumologic/sumologic
```
In the above command, since no arguments were specified, the `--reuse-values` flag will be used by default.


### Example to Upgrade using the `--version` flag:

```bash
helm upgrade collection sumologic/sumologic --reuse-values --version=<RELEASE-VERSION> -f config.yaml
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
 No newline at end of file
