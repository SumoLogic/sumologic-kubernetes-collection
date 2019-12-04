
# Advanced Configuration / Best Practices


### Multiline Log Support

By default, we use a regex that matches the first line of a multiline log starting with a date of the format : `2019-11-17 07:14:12`.

Users can specify their custom regex to detect the first line of a multiline log and parse the logs correctly.

New parsers can be defined under the `parsers` key of the fluent-bit configuration section in `values.yaml` as follows:

```
parsers:
  enabled: true
  regex:
    - name: multi_line
    regex: (?<log>^{"log":"\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}:\d{2}.*)
    - name: new_parser_name
    ## This parser matches lines that start with time of the format : 07:14:12
    regex: (?<log>^{"log":"\d{2}:\d{2}:\d{2}.*)
```

The regex used for `Parser_Firstline` needs to have at least one named capture group.

In order to use the newly define parser to detect the first line of multiline log, change the `Parser_Firstline` parameter in the `Input plugin` configuration of fluent-bit:

```bash
Parser_Firstline new_parser_name
```

Users can also use optional-extra parser to interpret and structure multiline entries.
When Multiline is On, if a line matched `Parser_Firstline`, continuation lines will be matched against `Parser_N` parsers (just if a previous Parser_Firstline match exists).

```bash
Parser_Firstline multi_line
Parser_1 optional_parser
```

### Fluentd File-based buffer

By default, we use the in-memory buffer for the Fluentd buffer, but for production environments we recommend users to use the file-based buffer instead.

Buffer configuration can be set in `values.yaml` under the `fluentd` key as follows:

```
fluentd:
## Option to specify the Fluentd buffer as file/memory.
   buffer: 
     type : "file"
```

Additional buffering and flushing parameters can be added in the `extraConf`, in the `fluentd` buffer section.

```
fluentd:
## Option to specify the Fluentd buffer as file/memory.
   buffer: 
     type : "file"
     extraConf: |-
       retry_exponential_backoff_base 2s
```

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

Once the config has been modified in the `values.yaml` file,  we need to run the `helm upgrade` in order to apply the changes.

```bash
$ helm upgrade collection sumologic/sumologic --reuse-values -f values.yaml
```
#### File path paramter:

We have defined several file paths where the buffer chunks will be stored. This parameter must be unique to avoid race condition problem.

These paths can be modified in the `values.yaml` under the `filePaths` section in the `fluentd` key .

Please make sure that you have **enough space in the path directory** . Running out of disk space is a problem frequently reported by users.

Reference link to official Fluentd buffer documentation: 
 - https://docs.fluentd.org/configuration/buffer-section
 - https://docs.fluentd.org/buffer/file