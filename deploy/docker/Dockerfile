FROM fluent/fluentd:v1.4.2-onbuild-1.0

# Use root account to use apk
USER root

COPY gems/fluent-plugin*.gem ./

RUN apk add --no-cache libexecinfo libexecinfo-dev

RUN apk add --no-cache snappy g++ snappy-dev

RUN apk add --no-cache --update --virtual .build-deps sudo build-base ruby-dev \
       && gem install concurrent-ruby \
       && gem install google-protobuf \
       && gem install kubeclient \
       && gem install lru_redux \
       && gem install snappy

RUN gem install fluent-plugin-s3 -v 1.1.4 \
       && gem install fluent-plugin-systemd -v 0.3.1 \
       && gem install fluent-plugin-record-modifier \
       && gem install fluent-plugin-kubernetes_metadata_filter -v 1.0.2 \
       && gem install fluent-plugin-sumologic_output -v 1.5.0 \
       && gem install fluent-plugin-concat -v 2.3.0 \
       && gem install fluent-plugin-rewrite-tag-filter -v 2.1.0 \
       && gem install fluent-plugin-prometheus -v 1.1.0 \
       && gem install fluent-plugin-kubernetes_sumologic

RUN gem install fluent-plugin-sumologic_output \
       && gem install fluent-plugin-carbon-v2 \
       && gem install fluent-plugin-prometheus-format \
       && gem install fluent-plugin-enhance-k8s-metadata \
       && gem install fluent-plugin-datapoint \
       && gem install fluent-plugin-rewrite-tag-filter \
       && gem install fluent-plugin-protobuf \
       && gem install fluent-plugin-events

RUN gem sources --clear-all \
       && apk del .build-deps \
       && rm -rf /home/fluent/.gem/ruby/2.5.0/cache/*.gem \
       && rm -f ./*.gem

# Default settings for log collection
ENV LOG_FORMAT "fields"
ENV FLUSH_INTERVAL "5s"
ENV NUM_THREADS "1"
ENV SOURCE_CATEGORY "%{namespace}/%{pod_name}"
ENV SOURCE_CATEGORY_PREFIX "kubernetes/"
ENV SOURCE_CATEGORY_REPLACE_DASH "/"
ENV SOURCE_NAME "%{namespace}.%{pod}.%{container}"
ENV KUBERNETES_META "true"
ENV KUBERNETES_META_REDUCE "false"
ENV MULTILINE_START_REGEXP "/^\w{3} \d{1,2}, \d{4}/"
ENV CONCAT_SEPARATOR ""
ENV ADD_TIMESTAMP "true"
ENV TIMESTAMP_KEY "timestamp"
ENV ADD_STREAM "true"
ENV ADD_TIME "true"
ENV K8S_METADATA_FILTER_WATCH "true"
ENV K8S_METADATA_FILTER_VERIFY_SSL "true"
ENV K8S_METADATA_FILTER_BEARER_CACHE_SIZE "1000"
ENV K8S_METADATA_FILTER_BEARER_CACHE_TTL "3600"
ENV VERIFY_SSL "true"

RUN mkdir -p /fluentd/conf.d

COPY ./fluent.conf /fluentd/conf.d/fluent.conf

USER fluent
