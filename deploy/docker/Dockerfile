FROM fluent/fluentd:v1.11.5-debian-1.0 AS builder

# Use root account to use apt
USER root

# Dependencies
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
        curl \
        g++ \
        gcc \
        git \
        libc-dev \
        libsnappy-dev \
        make \
        ruby-dev \
        sudo \
        unzip

# Fluentd plugin dependencies
RUN gem install \
        concurrent-ruby:1.1.5 \
        google-protobuf:3.9.2 \
        lru_redux:1.1.0 \
        net-http-persistent:3.1.0 \
        snappy:0.0.17 \
        specific_install:0.3.5

# Use unreleased Kubeclient version with persistent HTTP connections.
RUN gem specific_install https://github.com/abonas/kubeclient --ref 3267dc3fd02c49e3b19f1210ff7cb84c3b2a4478

# FluentD plugins to allow customers to forward data if needed to various cloud providers
RUN gem install \
        fluent-plugin-s3
        # TODO: Support additional cloud providers
        # && gem install fluent-plugin-google-cloud \
        # && gem install fluent-plugin-azure-storage-append-blob

# FluentD plugins from RubyGems
RUN gem install \
        fluent-plugin-systemd:1.0.2 \
        fluent-plugin-record-modifier:2.0.1 \
        fluent-plugin-sumologic_output:1.7.1 \
        fluent-plugin-concat:2.4.0 \
        fluent-plugin-rewrite-tag-filter:2.2.0 \
        fluent-plugin-prometheus:1.6.1

# Install Terraform
ENV TERRAFORM_VERSION 0.13.7
RUN mkdir /tmp/terraform \
 && curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform/terraform.zip \
 && cd /tmp/terraform \
 && unzip terraform.zip \
 && mv terraform /bin/terraform \
 && chmod +x /bin/terraform \
 && rm -rf /tmp/terraform

# FluentD plugins from this repository
COPY gems/fluent-plugin*.gem ./
RUN gem install \
        --local fluent-plugin-prometheus-format \
        --local fluent-plugin-kubernetes-metadata-filter \
        --local fluent-plugin-kubernetes-sumologic \
        --local fluent-plugin-enhance-k8s-metadata \
        --local fluent-plugin-datapoint \
        --local fluent-plugin-protobuf \
        --local fluent-plugin-events

# Start with fresh image
FROM fluent/fluentd:v1.11.5-debian-1.0

USER root

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
        libsnappy-dev

# Create directory for terraform configuration
RUN mkdir -p /terraform \
 && chown -R fluent /terraform

COPY --from=builder /bin/terraform /bin/terraform
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY ./fluent.conf /fluentd/etc/
COPY ./entrypoint.sh /bin/

# Allow installing gems by fluent user
RUN chown fluent /usr/local/bundle/*

USER fluent
