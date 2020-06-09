# Configuring Fluentd

Until now, Helm users have not been able to modify their Fluentd configuration outside of the specific parameters that we exposed in the `values.yaml` file. Now, we expose the ability to modify the Fluentd configuration as needed. 

Some use-cases include: 
 - custom log pipelines, 
 - adding Fluentd filter plugins (ex: fluentd throttle plugin), or 
 - adding Fluentd output plugins (ex: forward to both Sumo and S3)
 - additional configuration for sumologic output plugin

**NOTE:** Helm templating like
```bash
{{ .Values.fluentd.foo.bar | quote }}
```
will **NOT** work if they are specified within one of the below mentioned plugin conf sections, since they are in the `values.yaml` file and are therefore interpreted as literal strings. 

Below you can see a few examples of how this configuration can be set.

### Custom Log Pipelines
Now we have exposed an `extraLogs` parameter inside the `logs.containers` section of the `values.yaml` where you can add the output plugin for the custom log pipeline.

**NOTE:** This will only send the logs to Sumo if the logs are being collected correctly at the FluentBit level with an input plugin.

You can add a custom endpoint in `values.yaml`:

```yaml
sumologic:
  sources:
    logs:
      my-custom:
        name: My custom logs  # It's going to be visible on sumologic platform
```

The `custom-log` will be available in Fluentd as the `SUMO_ENDPOINT_MY_CUSTOM_LOGS_SOURCE` environmental variable.

```yaml
fluentd:
  logs:
    extraLogs: |-
      <match custom.tag>
        @type sumologic
        @id sumologic.endpoint.custom.log.endpoint
        source_category k8s/custom
        source_name custom
        data_type logs
        log_key log
        endpoint "#{ENV['SUMO_ENDPOINT_MY_CUSTOM_LOGS_SOURCE']}"
        proxy_uri "#{ENV['PROXY_URI']}"
        verify_ssl "#{ENV['VERIFY_SSL']}"
        log_format "json_merge"
        add_timestamp "false"
        <buffer>
          @type memory
          @include buffer.output.conf
        </buffer>
      </match>
```

### Adding Fluentd Filter plugin

You can add any of the Fluentd filter plugins in the `extraFilterPluginConf` section to filter data based on your needs.

**Note:** This is specific to the container logs pipeline only and will not work for other logs.

The below example uses the `grep` filter to match any record that satisfies the following conditions:
 - The value of the "message" field contains "cool"
 - The value of the "message" field does NOT contain "uncool"

```yaml
fluentd:
  logs:
    containers:
      extraFilterPluginConf: |-
        <filter containers.**>
          @type grep
          <regexp>
            key message
            pattern /cool/
          </regexp>
          <exclude>
            key message
            pattern /uncool/
          </exclude> 
        </filter>
```
Reference documentation: [Fluentd Filter Plugin](https://docs.fluentd.org/filter)

## Override Fluentd Output plugin to forward data to Sumo as well as S3
The example below shows how you can override the entire output section for the container logs pipeline.

You can look at the Default output section [here](https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/master/deploy/helm/sumologic/conf/logs/logs.source.containers.conf#L51)

```yaml
fluentd:
  logs:
    containers:
      overrideOutputConf: |-
        <match containers.**>
          @type copy
          <store>
            @type sumologic
            @id sumologic.endpoint.logs
            @include logs.output.conf
            # Helm templating does not work in the `values.yaml` file so, you will *NOT* have an option to choose the file/memory buffer configs based on the fluentd.buffer.type value and will have to write them explicitly. 
            <buffer>
              @type file
              path /fluentd/buffer/logs.containers
              @include buffer.output.conf
            </buffer>
          </store>
          <store>
            @type s3
            aws_key_id YOUR_AWS_KEY_ID
            aws_sec_key YOUR_AWS_SECRET_KEY
            s3_bucket YOUR_S3_BUCKET_NAME
            s3_region YOUR_S3_BUCKET_REGION
            path logs/
            # if you want to use ${tag} or %Y/%m/%d/ like syntax in path / s3_object_key_format,
            # need to specify tag for ${tag} and time for %Y/%m/%d in <buffer> argument.
            <buffer tag,time>
              @type file
              path /fluentd/buffer/logs.containers.s3
              timekey 3600 # 1 hour partition
              timekey_wait 10m
              timekey_use_utc true # use utc
              chunk_limit_size 256m
            </buffer>
          </store>
        </match>
```

### Additional Buffer/Flush/Retry Config parameters for Sumologic Output Plugin

The following config parameters are set by default and their values can be set by changing the respective config in `values.yaml`. 

```bash
compress gzip
flush_interval {{ .Values.fluentd.buffer.flushInterval | quote }}
flush_thread_count {{ .Values.fluentd.buffer.numThreads | quote }}
chunk_limit_size {{ .Values.fluentd.buffer.chunkLimitSize | quote }}
total_limit_size {{ .Values.fluentd.buffer.totalLimitSize | quote }}
queued_chunks_limit_size {{ .Values.fluentd.buffer.queueChunkLimitSize | quote }}
overflow_action drop_oldest_chunk
```
However, if you wish to add any additional Buffer/Flush/Retry Configs, you can do so in the `extraConf` section.

```yaml
fluentd:
  logs:
    output:
      extraConf: |-
        retry_wait 2s
        flush_at_shutdown true 
```
