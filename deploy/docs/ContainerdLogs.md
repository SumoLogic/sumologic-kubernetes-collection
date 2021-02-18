# Configuration for containerd log format

In order to collect logs in CRI-O log format modify Fluent Bit inputs to following form:

```yaml
fluent-bit:
  config:
    inputs: |
      [INPUT]
          Name                tail
          Path                /var/log/containers/*.log
          Docker_Mode         On
          Parser              containerd
          Tag                 containers.*
          Refresh_Interval    1
          Rotate_Wait         60
          Mem_Buf_Limit       5MB
          Skip_Long_Lines     On
          DB                  /tail-db/tail-containers-state-sumo.db
          DB.Sync             Normal
```

then `containerd` parser defined in `values.yaml` in `customParsers` section will be in use:

```text
          Name         containerd
          Format       regex
          Regex        ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%LZ
```

and providing that CRI-O logs have this form:

```
```

they they have following form in Sumo:

```json

```

In order to have time from log lines as a string value in logs in Sumo
remove following lines from `containerd` parser configuration:

```text
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%LZ
```

and then `time` key will be visiable in Sumo:

```json
```

For details related to Parser configuration please see
[Parser documentation](https://docs.fluentbit.io/manual/v/1.6/pipeline/parsers/regular-expression).

**Notice**: Multiline feature is not yet supported for logs in containerd format and
it is recommended to turn off multiline option in Fluentd logs configuration:

```yaml
fluentd:
  logs:
    containers:
      enabled: false
```
