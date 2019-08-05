FROM fluent/fluentd:v1.6.2-1.0

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

# FluentD plugins from RubyGems
RUN gem install fluent-plugin-s3 -v 1.1.4 \
       && gem install fluent-plugin-systemd -v 0.3.1 \
       && gem install fluent-plugin-record-modifier \
       && gem install fluent-plugin-kubernetes_metadata_filter -v 1.0.2 \
       && gem install fluent-plugin-sumologic_output -v 1.5.0 \
       && gem install fluent-plugin-concat -v 2.3.0 \
       && gem install fluent-plugin-rewrite-tag-filter -v 2.1.0 \
       && gem install fluent-plugin-prometheus -v 1.4.0 \
       && gem install fluent-plugin-kubernetes_sumologic -v 2.4.2

# FluentD plugins from this repository
RUN gem install fluent-plugin-prometheus-format \
       && gem install fluent-plugin-enhance-k8s-metadata \
       && gem install fluent-plugin-datapoint \
       && gem install fluent-plugin-rewrite-tag-filter \
       && gem install fluent-plugin-protobuf \
       && gem install fluent-plugin-events

RUN gem sources --clear-all \
       && apk del .build-deps \
       && rm -rf /home/fluent/.gem/ruby/2.5.0/cache/*.gem \
       && rm -f ./*.gem

RUN mkdir -p /fluentd/conf.d

COPY ./fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/

USER fluent
