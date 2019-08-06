FROM fluent/fluentd:v1.6.3-debian-1.0

# Use root account to use apt
USER root

# below RUN includes plugin as examples elasticsearch is not required
# you may customize including plugins as you wish
RUN buildDeps="sudo make gcc g++ libc-dev ruby-dev libsnappy-dev" \
 && apt-get update \
 && apt-get install -y --no-install-recommends $buildDeps

COPY gems/fluent-plugin*.gem ./

# Fluentd plugin dependencies
RUN gem install concurrent-ruby \
       && gem install google-protobuf \
       && gem install kubeclient \
       && gem install lru_redux \
       && gem install snappy

# FluentD plugins to allow customers to forward data if needed to various cloud providers
RUN gem install fluent-plugin-s3
       # TODO: Support additional cloud providers
       # && gem install fluent-plugin-google-cloud \
       # && gem install fluent-plugin-azure-storage-append-blob

# FluentD plugins from RubyGems
RUN gem install fluent-plugin-systemd -v 1.0.2 \
       && gem install fluent-plugin-record-modifier -v 2.0.1 \
       && gem install fluent-plugin-kubernetes_metadata_filter -v 2.2.0 \
       && gem install fluent-plugin-sumologic_output -v 1.5.0 \
       && gem install fluent-plugin-concat -v 2.4.0 \
       && gem install fluent-plugin-rewrite-tag-filter -v 2.2.0 \
       && gem install fluent-plugin-prometheus -v 1.5.0 \
       && gem install fluent-plugin-kubernetes_sumologic -v 2.4.2

# FluentD plugins from this repository
RUN gem install fluent-plugin-prometheus-format \
       && gem install fluent-plugin-enhance-k8s-metadata \
       && gem install fluent-plugin-datapoint \
       && gem install fluent-plugin-rewrite-tag-filter \
       && gem install fluent-plugin-protobuf \
       && gem install fluent-plugin-events

RUN sudo gem sources --clear-all \
 && SUDO_FORCE_REMOVE=yes \
    apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

COPY ./fluent.conf /fluentd/etc/
COPY ./entrypoint.sh /bin/

USER fluent
