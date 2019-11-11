
# Upgrading with Helm

When a new version of a chart is released, or when you want to change the configuration of your release, you can use the helm upgrade command.

This command upgrades a release to a specified version of a chart and/or updates chart values.

Required arguments are release and chart.

The chart argument can be one of: - a chart reference; use `–version` flag for versions other than latest, - a path to a chart directory, - a packaged chart, - a fully qualified URL.

An upgrade takes an existing release and upgrades it according to the information you provide. Because Kubernetes charts can be large and complex, Helm tries to perform the least invasive upgrade. It will only update things that have changed since the last release.

If required, there are two ways to pass configuration data:

- `--values` or `-f`: Specify a YAML file with overrides. This can be specified multiple times and the rightmost file will take precedence

- `--set` (and its variants `--set-string` and `--set-file`): Specify overrides on the command line.


```bash

helm upgrade [RELEASE] [CHART] [flags]

```  

Some useful Options

``` bash

--debug 		Enable verbose output

--dry-run 		Simulate an upgrade

-h, --help 		help for upgrade

--no-hooks 		Disable pre/post upgrade hooks

--reset-values 	When upgrading, reset the values to the ones built into the chart

--reuse-values 	When upgrading, reuse the last releases values and merge in any overrides from the command line via --set and -f

--set string	Array Set values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)

--set-file 		stringArray Set values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)

--set-string 	stringArray Set STRING values on the command line (can specify multiple or separate values with commas: key1=val1,key2=val2)

--version 		Specify the exact chart version to use. If this is not specified, the latest version is used

```


To edit or append to the existing customized values, add the `–reuse-values` flag, otherwise any existing customized values are ignored.

If no chart value arguments are provided on the command line, any existing customized values are carried forward, i.e. the `--reuse-values` flag will be used by default. If you want to revert to just the values provided in the chart, use the `-–reset-values` flag.

And if there exists `--set/--set-file/--set-string/--values/-f` , the `--reset-values` flag will be used by default.

You can specify any of the chart value flags multiple times. The priority will be given to the last (right-most) value specified. For example, if both `myvalues.yaml` and `override.yaml` contained a key called ‘Test’, the value set in `override.yaml` would take precedence:  

```bash
$ helm upgrade collection sumologic/sumologic --reuse-values -f myvalues.yaml -f override.yaml
```

In the above case, the `collection` release is upgraded with the same chart, but with a new  key-value pair in the YAML file:
```bash
Test: true
```
  
We can use helm get values to see whether that new setting took effect.
```bash
$ helm get values collection
Test: true
```

The helm get command is a useful tool for looking at a release in the cluster. And as we can see above, it shows that our new values from `override.yaml` were deployed to the cluster.
