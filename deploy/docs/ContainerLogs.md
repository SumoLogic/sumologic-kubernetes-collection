# Container log parsing

- [Container log parsing](#container-log-parsing)
  - [Configuration for Docker log format](#configuration-for-docker-log-format)
  - [Configuration for CRI-O log format](#configuration-for-cri-o-log-format)
  - [Configuration for containerd log format](#configuration-for-containerd-log-format)

## Configuration for Docker log format

In order to collect logs in Docker format, modify Fluent Bit input section to following form:

```yaml
fluent-bit:
  config:
    inputs: |
          Name                tail
          Path                /var/log/containers/*.log
          Docker_Mode         On
          Docker_Mode_Parser  multi_line
          Tag                 containers.*
          Refresh_Interval    1
          Rotate_Wait         60
          Mem_Buf_Limit       5MB
          Skip_Long_Lines     On
          DB                  /tail-db/tail-containers-state-sumo.db
          DB.Sync             Normal

```

Adjust `multi_line` parser defined in `values.yaml` in `customParsers` to pattern which starts log entry:

```
      [PARSER]
          Name        multi_line
          Format      regex
          Regex       (?<log>^{"log":"\d{4}-\d{1,2}-\d{1,2}.\d{2}:\d{2}:\d{2}.*)
```

Assuming that log is generated in following way;

```bash
echo "$(date '+%Y-%m-%dT%H:%M:%S.%s') this is the first line
        this the second line"
```

and it has this form in log file in `/var/log/containers/*`:

```
{"log":"2021-02-19T12:09:26.1613736566 this is the first line\n","stream":"stdout","time":"2021-02-19T12:09:26.739226803Z"}
{"log":"  this the second line\n","stream":"stdout","time":"2021-02-19T12:09:26.739254308Z"}
```

Log will be visible in Sumo in this form:

```json
{
   "timestamp":1613736567740,
   "log":"2021-02-19T12:09:26.1613736566 this is the first line\n  this the second line",
   "stream":"stdout",
   "time":"2021-02-19T12:09:26.739254308Z"
}
```

## Configuration for CRI-O log format

In order to collect logs in CRI-O log format, modify Fluent Bit input section to following form:

```yaml
fluent-bit:
  config:
    inputs: |
      [INPUT]
          Name                tail
          Path                /var/log/containers/*.log
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

```
      [PARSER]
          Name         crio
          Format       regex
          Regex        ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%L%z
```

and disable `multiline` option in Fluentd configuration:

```yaml
fluentd:
  logs:
    containers:
      multiline:
        enabled: false
```

CRI-O log in this form:

```
2021-02-18T11:34:21.529641620+00:00 stdout F this is log message
```

will have following form in Sumo:

```json
{
   "timestamp":1613650078811,
   "stream":"stdout",
   "logtag":"F",
   "log":"this is a log message"
}
```

In order to have time from log line as a string value in log in Sumo please
remove the following lines from `crio` parser configuration:

```
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%L%z
```

and `time` key will be visible in Sumo:

```json
{
   "timestamp":1613650456722,
   "time":"2021-02-18T12:14:16.722375295+00:00",
   "stream":"stdout",
   "logtag":"F",
   "log":"this is a log message"
}
```

## Configuration for containerd log format

In order to collect logs in containerd log format modify, Fluent Bit input section to following form:

```yaml
fluent-bit:
  config:
    inputs: |
      [INPUT]
          Name                tail
          Path                /var/log/containers/*.log
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

```
      [PARSER]
          Name         containerd
          Format       regex
          Regex        ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%LZ
```

and disable `multiline` option in Fluentd configuration:

```yaml
fluentd:
  logs:
    containers:
      multiline:
        enabled: false
```

containerd log in this form:

```
2021-02-18T11:34:21.529641620+00:00 stdout F this is log message
```

will have following form in Sumo:

```json
{
   "timestamp":1613653807337,
   "stream":"stdout",
   "logtag":"F",
   "log":"this is a log message"
}
```

In order to have time from log line as a string value in log in Sumo please
remove the following lines from `containerd` parser configuration:

```
          Time_Key     time
          Time_Format  %Y-%m-%dT%H:%M:%S.%LZ
```

and `time` key will be visible in Sumo:

```json
{
   "timestamp":1613654044683,
   "time":"2021-02-18T13:14:04.683042846Z",
   "stream":"stdout",
   "logtag":"F",
   "log":"this is a log message"
}
```
