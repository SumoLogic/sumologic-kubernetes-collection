# Advanced Configuration / Best Practices


### Multiline Log Support

By default, we use a regex that matches the first line of multiline logs that start with dates in the following format: `2019-11-17 07:14:12`.

If your logs have a different date format you can provide a custom regex to detect the first line of multiline logs. See [collecting multiline logs](https://help.sumologic.com/?cid=49494) for details on configuring a boundary regex.

New parsers can be defined under the `parsers` key of the fluent-bit configuration section in the `values.yaml` file as follows:

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

To use the newly defined parser to detect the first line of multiline logs, change the `Parser_Firstline` parameter in the `Input plugin` configuration of fluent-bit:

```bash
Parser_Firstline new_parser_name
```

You can also use the optional-extra parser to interpret and structure multiline entries.
When Multiline is On, if the first line matches `Parser_Firstline`, the rest of the lines will be matched against `Parser_N`.

```bash
Parser_Firstline multi_line
Parser_1 optional_parser
```
### Log lines over 16KB are truncated
Docker daemon has a limit of 16KB/line so if a log line is greater than that, it might be truncated in Sumo.
To fix this, fluent-bit exposes a parameter:  
``` bash
Docker_Mode  On
```
If enabled, the plugin will recombine split Docker log lines before passing them to any parser. This mode cannot be used at the same time as Multiline.
Reference: https://docs.fluentbit.io/manual/v/1.3/input/tail#docker_mode

### Fluentd autoscaling:

We have provided an option to enable autoscaling for Fluentd deployments. This is disabled by default. 

To enable autoscaling for Fluentd:

- Enable metrics-server dependency
  Note: If metrics-server is already installed, this step is not required.
  ```
  ## Configure metrics-server
  ## ref: https://github.com/helm/charts/blob/master/stable/metrics-server/values.yaml
  metrics-server:
    enabled: true
  ```

- Enable autoscaling for Fluentd
```
fluentd:
  ## Option to turn autoscaling on for fluentd and specify metrics for HPA.
  autoscaling:
    enabled: true
```


### Fluentd File-based buffer

By default, we use the in-memory buffer for the Fluentd buffer, however for production environments we recommend you use the file-based buffer instead.

The buffer configuration can be set in the `values.yaml` file under the `fluentd` key as follows:

```
fluentd:
  ## Option to specify the Fluentd buffer as file/memory.
  buffer: "file"
```

We have defined several file paths where the buffer chunks are stored.

Ensure that you have **enough space in the path directory**. Running out of disk space is a common problem.

Once the config has been modified in the `values.yaml` file you need to run the `helm upgrade` command to apply the changes.

```bash
$ helm upgrade collection sumologic/sumologic --reuse-values -f values.yaml
```

See the following links to official Fluentd buffer documentation: 
 - https://docs.fluentd.org/configuration/buffer-section
 - https://docs.fluentd.org/buffer/file
