# Configuration for CRI-O log format

In order to collect logs in CRI-O log format modify Fluent Bit inputs to following form:

```yaml
fluent-bit:
  config:
    inputs: |
      [INPUT]
          Name                tail
          Path                /var/log/containers/*.log
          Docker_Mode         On
          Parser              crio
          Tag                 containers.*
          Refresh_Interval    1
          Rotate_Wait         60
          Mem_Buf_Limit       5MB
          Skip_Long_Lines     On
          DB                  /tail-db/tail-containers-state-sumo.db
          DB.Sync             Normal
```

then `crio` parser defined in `values.yaml` in `customParsers` section will be in use:

```text
      [PARSER]
          Name         crio
          Format       regex
          Regex        ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%L%z
```

and providing that CRI-O log has this form:

```
2021-02-18T11:34:21.529641620+00:00 stdout F this is log message
```

it will have following form in Sumo:

```json
{
   "timestamp":1613650078811,
   "stream":"stdout",
   "logtag":"F",
   "log":"this is a log message"
}
```

with multiline enabled:

```json
{
   "timestamp":1613649779117,
   "log":"this is a log message",
   "stream":"stdout",
   "time":null
}
```

In order to have time from log line as a string value in log in Sumo please
remove following lines from `crio` parser configuration:

```text
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%L%z
```

and then `time` key will be visible in Sumo:

```json
{
   "timestamp":1613650456722,
   "time":"2021-02-18T12:14:16.722375295+00:00",
   "stream":"stdout",
   "logtag":"F",
   "log":"this is a log message"
}
```

with multiline enabled:

```json
{
   "timestamp":1613650766187,
   "log":"this is a log message",
   "stream":"stdout",
   "time":"2021-02-18T12:19:26.187082851+00:00"
}
```

For details related to Parser configuration please see
[Parser documentation](https://docs.fluentbit.io/manual/v/1.6/pipeline/parsers/regular-expression).

[old](https://fluentbit.io/documentation/0.13/parser/)