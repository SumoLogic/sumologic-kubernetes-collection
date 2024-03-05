# Configuration

This document describes how configuration works and what are the outcomes.

## Merging configuration

In the documentation we usually shows part of the configuration which should be applied.

For example we have this configuration snippet:

```yaml
sumologic:
  clusterName: my-cluster
```

### Valid configuration

Such configuration snippets should be merged with your current configuration.
Let's say you already have `values.yaml` with the given content:

```yaml
sumologic:
  podLabels:
    environment: monitoring
```

So, your updated `values.yaml` should look like the following way:

```yaml
sumologic:
  clusterName: my-cluster
  podLabels:
    environment: monitoring
```

As you can see, `sumologic` is typed only once.

### Invalid configuration

If you just copy snippet to your current file like this:

```yaml
sumologic:
  podLabels:
    environment: monitoring
sumologic:
  clusterName: my-cluster
```

it will be parsed as:

```yaml
sumologic:
  clusterName: my-cluster
```

and the result won't meet the expectations

## Keeping configuration

Configuration should be stored in one or multiple files.
For security reason it is better to keep sensitive information in separate file.

To apply configuration it needs to be provided by adding `-f ${config_path} -f ${config_path_2} ...` to `helm` command.

If multiple files contains same configuration keys,
they will be merged and eventually overrided by the last supplied file.

For example, let's say we have two configuration files:

- values.yaml

  ```yaml
  sumologic:
    clusterName: my-cluster
    accessId: a
    accessKey: b
  ```

- values-override.yaml

  ```yaml
  sumologic:
    clusterName: overrided-cluster
  ```

applying files with `-f values.yaml -f values-override.yaml` will take the same affect like applying one file with the following content:

```
sumologic:
  clusterName: overrided-cluster
  accessId: a
  accessKey: b
```

## Applying configuration

Configuration is not applied automatically. Every change should be applied using `helm upgrade` command.
