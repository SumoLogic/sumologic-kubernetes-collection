
# Advanced Configuration / Best Practices


### Multiline Log Support

By default, we use a regex that matches the first line of a multiline log starting with a date of the format : `2019-11-17 07:14:12`.

Users can specify their custom regex to detect first line of a multiline log and parse the logs correctly.

New parsers can be defined under the `parsers` key of the fluent-bit configuration section in `values.yaml` as follows:

```
parsers:
  enabled: true
  regex:
    - name: new_parser_name
    regex: (?<log>^{"log":"\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}:\d{2}.*)
```

The regex needs to have at least one named capture group.

In order to use the newly define parser, change the `Parser_Firstline` parameter in the `Input plugin` configuration of fluent-bit:

```bash
Parser_Firstline new_parser_name
```


### Fluentd File-based buffer

By default, we use the in-memory buffer for the Fluentd buffer, but for production environments we recommend users to use the file-based buffer instead.

Buffer configuration can be set in `values.yaml` under the `sumologic` key as follows:

```
fluentd:
## Option to specify the Fluentd buffer as file/memory.
   buffer: "file"
```

Additional buffering and flushing parameters can be added in the `buffer.output.conf`config file, to be used by all buffer sections.

We recommend the following configurations for the file-based buffer:

#### Buffering parameters:
```
flush_interval 5s

flush_thread_count 4

chunk_limit_size 100k

total_limit_size 128m
```

####  Flushing parameters:
```
retry_wait 5

retry_forever false

retry_timeout 2h

retry_exponential_backoff_base 2
```

Reference link to official Fluentd buffer documentation: https://docs.fluentd.org/configuration/buffer-section