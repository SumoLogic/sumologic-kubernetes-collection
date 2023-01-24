# Adding Additional Fluentd Plugins

To add additional Fluentd plugins, you can modify `user-values.yaml` or create a new container image from our provided image.

## Configuration

**Note**: If your plugin requires additional system libraries, it cannot be installed this way.

```yaml
fluentd:
  additionalPlugins:
    - fluent-plugin-route
    - fluent-plugin-aws-elasticsearch-service
```

## Docker

Use the [Sumo Logic Fluentd](https://gallery.ecr.aws/sumologic/kubernetes-fluentd) image as the base image.

**Note:** To choose between Debian-based and Alpine-based image, see
[Choosing Fluentd base image](best-practices.md#choosing-fluentd-base-image).

To create a Debian-based image:

```dockerfile
FROM public.ecr.aws/sumologic/kubernetes-fluentd:<RELEASE>

USER root

# Install any system dependencies if required.
RUN apt-get install some-dependency

# Install the required plugins.
RUN gem install fluent-plugin-route
RUN gem install fluent-plugin-aws-elasticsearch-service

# Use numeric user ID - see https://github.com/SumoLogic/sumologic-kubernetes-fluentd/pull/118
USER 999:999
```

To create an Alpine-based image:

```dockerfile
FROM public.ecr.aws/sumologic/kubernetes-fluentd:<RELEASE>-alpine

USER root

# Install any system dependencies if required.
RUN apk add --no-cache some-dependency

# Install the required plugins.
RUN gem install fluent-plugin-route
RUN gem install fluent-plugin-aws-elasticsearch-service

# Use numeric user ID - see https://github.com/SumoLogic/sumologic-kubernetes-fluentd/pull/118
USER 999:999
```
