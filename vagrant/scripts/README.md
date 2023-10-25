# Helper Scripts

This directory contains scripts which may be useful inside and/or outside of vagrant environment.

## Diff values

[diff_values.py](./diff_values.py) is for extracting non-default values from `user-values.yaml`. It compares given `user-values.yaml` with
the helm chart `values.yaml` for specified `--version` and outputs only overrides. If `--version` is not set, script is going to compare
with latest helm chart version.

Let's consider the following example:

`user-values.yaml`:

```yaml
sumologic:
  events:
    sourceType: otlp
```

```bash
$ ./vagrant/scripts/diff_values.py --version=v3.15.0 user-values.yaml
sumologic:
  events:
    sourceType: otlp

$ ./vagrant/scripts/diff_values.py --version=v4.0.0 user-values.yaml
{}
```
