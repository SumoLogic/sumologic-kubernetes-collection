# Advanced Configuration / Best Practices


### Multiline Log Support

By default, we use a regex that matches the first line of a multiline log starting with a date of the format: `2019-11-17 07:14:12`.

You can specify a custom regex to detect the first line of a multiline logs to parse them correctly.

New parsers can be defined under the `parsers` key of the fluent-bit configuration section in  the `values.yaml` file as follows:

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

To use the newly define parser to detect the first line of multiline log, change the `Parser_Firstline` parameter in the `Input plugin` configuration of fluent-bit:

```bash
Parser_Firstline new_parser_name
```

You can also use  the optional-extra parser to interpret and structure multiline entries.
When Multiline is On, if a line matched `Parser_Firstline`, continuation lines will be matched against `Parser_N` parsers (just if a previous Parser_Firstline match exists).

```bash
Parser_Firstline multi_line
Parser_1 optional_parser
```

#### Fluentd autoscaling:

We have provided an option to enable autoscaling for fluentd deployments. This is disabled by default. 

To enable autoscaling for fluentd:

- Enable metrics-server dependency
  Note: if metrics-server is already installed, this step is not required.
  ```
  ## Configure metrics-server
  ## ref: https://github.com/helm/charts/blob/master/stable/metrics-server/values.yaml
  metrics-server:
    enabled: true
  ```

- Enable autoscaling for fluentd
```
fluentd:
  ## Option to turn autoscaling on for fluentd and specify metrics for HPA.
  autoscaling:
    enabled: true
```


### Fluentd File-based buffer

By default, we use the in-memory buffer for the Fluentd buffer, but for production environments we recommend users to use the file-based buffer instead.

Buffer configuration can be set in `values.yaml` under the `fluentd` key as follows:

```
fluentd:
  ## Option to specify the Fluentd buffer as file/memory.
  buffer: "file"
```

We have defined several file paths where the buffer chunks will be stored.

Please make sure that you have **enough space in the path directory**. Running out of disk space is a problem frequently reported by users.

Once the config has been modified in the `values.yaml` file,  you need to run the `helm upgrade` command to apply the changes.

```bash
$ helm upgrade collection sumologic/sumologic --reuse-values -f values.yaml
```

Reference link to official Fluentd buffer documentation: 
 - https://docs.fluentd.org/configuration/buffer-section
 - https://docs.fluentd.org/buffer/file