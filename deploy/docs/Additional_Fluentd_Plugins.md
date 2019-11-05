# Adding Additional Fluentd Plugins
To add additional Fluentd plugins, you can simply create a new Docker image from our provided Docker image.
 
__Note__: You will want to update `<RELEASE>` to the [docker tag](https://hub.docker.com/r/sumologic/kubernetes-fluentd/tags) you wish to use.

```
FROM sumologic/kubernetes-fluentd:<RELEASE>

USER root
RUN gem install fluent-plugin-aws-elasticsearch-service

USER fluent
```
