# Adding Additional Fluentd Plugins

To add additional Fluentd plugins, you can modify `values.yaml` or create a new Docker image from our provided Docker image.

## Configuration

__Note__: If your plugin requires additional system libraries, it cannot be installed this way.

```yaml
fluentd:
  additionalPlugins:
    - fluent-plugin-route
    - fluent-plugin-aws-elasticsearch-service
```

## Docker
 
__Note__: You will want to update `<RELEASE>` to the [docker tag](https://hub.docker.com/r/sumologic/kubernetes-fluentd/tags) you wish to use.

```dockerfile
FROM sumologic/kubernetes-fluentd:<RELEASE>

USER root
# Add the plugins you wish to install below.
RUN gem install fluent-plugin-route
RUN gem install fluent-plugin-aws-elasticsearch-service

USER fluent
```
