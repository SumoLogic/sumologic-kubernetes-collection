FROM fluent/fluentd:v1.3.2-debian AS builder

ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

COPY gems/fluent-plugin*.gem ./

# New fluent image dynamically creates user in entrypoint
RUN apt-get update && \
    apt-get install -y build-essential ruby-dev libffi-dev libsystemd-dev && \
    gem install fluent-plugin-s3 -v 1.1.4 && \
    gem install fluent-plugin-systemd -v 0.3.1 && \
    gem install fluent-plugin-record-reformer -v 0.9.1 && \
    gem install fluent-plugin-kubernetes_metadata_filter -v 1.0.2 && \
    gem install fluent-plugin-sumologic_output -v 1.4.0 && \
    gem install fluent-plugin-concat -v 2.3.0 && \
    gem install fluent-plugin-rewrite-tag-filter -v 2.1.0 && \
    gem install fluent-plugin-prometheus -v 1.1.0 && \
    gem install fluent-plugin-kubernetes_sumologic && \
    rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem && \
    gem sources -c && \
    apt-get remove --purge -y build-essential ruby-dev libffi-dev libsystemd-dev && \
    rm -rf /var/lib/apt/lists/*

FROM fluent/fluentd:v1.4.2-onbuild-1.0

# Use root account to use apk
USER root

COPY gems/fluent-plugin*.gem ./

RUN apk add --no-cache libexecinfo libexecinfo-dev

RUN apk add --no-cache snappy g++ snappy-dev

RUN apk add --no-cache --update --virtual .build-deps sudo build-base ruby-dev \
       && gem install google-protobuf \
       && gem install snappy

RUN gem install fluent-plugin-sumologic_output \
       && gem install fluent-plugin-carbon-v2 \
       && gem install fluent-plugin-prometheus-format \
       && gem install fluent-plugin-datapoint \
       && gem install fluent-plugin-rewrite-tag-filter \
       && gem install fluent-plugin-protobuf

RUN gem sources --clear-all \
       && apk del .build-deps \
       && rm -rf /home/fluent/.gem/ruby/2.5.0/cache/*.gem \
       && rm -f ./*.gem

RUN mkdir -p /fluentd/conf.d

COPY ./fluent.conf /fluentd/conf.d/fluent.conf

COPY --from=builder /var/lib/gems /var/lib/gems

USER fluent