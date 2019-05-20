FROM fluent/fluentd:v1.4.2-onbuild-1.0

# Use root account to use apk
USER root

COPY gems/fluent-plugin*.gem ./

RUN apk add --no-cache libexecinfo libexecinfo-dev

RUN apk add --no-cache snappy g++ snappy-dev

RUN apk add --no-cache --update --virtual .build-deps sudo build-base ruby-dev \
       && gem install google-protobuf \
       && gem install kubeclient \
       && gem install lru_redux \
       && gem install snappy

RUN gem install fluent-plugin-sumologic_output \
       && gem install fluent-plugin-carbon-v2 \
       && gem install fluent-plugin-prometheus-format \
       && gem install fluent-plugin-enhance-k8s-metadata \
       && gem install fluent-plugin-datapoint \
       && gem install fluent-plugin-rewrite-tag-filter \
       && gem install fluent-plugin-protobuf

RUN gem sources --clear-all \
       && apk del .build-deps \
       && rm -rf /home/fluent/.gem/ruby/2.5.0/cache/*.gem \
       && rm -f ./*.gem

RUN mkdir -p /fluentd/conf.d

COPY ./fluent.conf /fluentd/conf.d/fluent.conf

USER fluent
