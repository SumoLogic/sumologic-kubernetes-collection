FROM fluent/fluentd:v1.11.1-debian-1.0 AS builder

# Use root account to use apt
USER root

# Build dependencies
RUN buildDeps="sudo make gcc g++ libc-dev ruby-dev libsnappy-dev" \
 && apt-get update \
 && apt-get install -y --no-install-recommends $buildDeps

COPY gems/fluent-plugin*.gem ./

# Fluentd plugin dependencies
RUN gem install concurrent-ruby -v 1.1.5 \
       && gem install google-protobuf -v 3.9.2 \
       && gem install kubeclient -v 4.9.1 \
       && gem install lru_redux -v 1.1.0 \
       && gem install snappy -v 0.0.17

# FluentD plugins to allow customers to forward data if needed to various cloud providers
RUN gem install fluent-plugin-s3
       # TODO: Support additional cloud providers
       # && gem install fluent-plugin-google-cloud \
       # && gem install fluent-plugin-azure-storage-append-blob

# FluentD plugins from RubyGems
RUN gem install fluent-plugin-systemd -v 1.0.2 \
       && gem install fluent-plugin-record-modifier -v 2.0.1 \
       && gem install fluent-plugin-kubernetes_metadata_filter -v 2.4.1 \
       && gem install fluent-plugin-sumologic_output -v 1.7.1 \
       && gem install fluent-plugin-concat -v 2.4.0 \
       && gem install fluent-plugin-rewrite-tag-filter -v 2.2.0 \
       && gem install fluent-plugin-prometheus -v 1.6.1

# FluentD plugins from this repository
RUN gem install --local fluent-plugin-prometheus-format \
       && gem install --local fluent-plugin-kubernetes-sumologic \
       && gem install --local fluent-plugin-enhance-k8s-metadata \
       && gem install --local fluent-plugin-datapoint \
       && gem install --local fluent-plugin-protobuf \
       && gem install --local fluent-plugin-events

# Run dependencies
RUN apt-get update \
 && apt-get install -y curl \
 && apt-get install -y unzip

# Install Terraform
ENV TERRAFORM_VERSION 0.12.26
RUN mkdir /tmp/terraform && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform/terraform.zip && \
    cd /tmp/terraform && \
    unzip terraform.zip && \
    mv terraform /bin/terraform && \
    chmod +x /bin/terraform && \
    rm -rf /tmp/terraform

# Start with fresh image
FROM fluent/fluentd:v1.11.1-debian-1.0

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends libsnappy-dev

# Create directory for terraform configuration
RUN mkdir -p /terraform && \
    chown -R fluent /terraform

COPY --from=builder /bin/terraform /bin/terraform
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY ./fluent.conf /fluentd/etc/
COPY ./entrypoint.sh /bin/

# Allow installing gems by fluent user
RUN chown fluent /usr/local/bundle/*

USER fluent