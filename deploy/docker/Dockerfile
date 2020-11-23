FROM fluent/fluentd:v1.11.3-debian-1.0 AS builder

# Use root account to use apt
USER root

# Dependencies
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
        curl \
        g++ \
        gcc \
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
        kubeclient:4.9.1 \
        lru_redux:1.1.0 \
        snappy:0.0.17

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
        fluent-plugin-kubernetes_metadata_filter:2.5.2 \
        fluent-plugin-sumologic_output:1.7.1 \
        fluent-plugin-concat:2.4.0 \
        fluent-plugin-rewrite-tag-filter:2.2.0 \
        fluent-plugin-prometheus:1.6.1

# Install Terraform ...
ENV TERRAFORM_VERSION 0.12.29
RUN mkdir /tmp/terraform \
 && curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform/terraform.zip \
 && cd /tmp/terraform \
 && unzip terraform.zip \
 && mv terraform /bin/terraform \
 && chmod +x /bin/terraform

# ... and providers
COPY main.tf /tmp/terraform
RUN cd /tmp/terraform \
 && terraform init

# FluentD plugins from this repository
COPY gems/fluent-plugin*.gem ./
RUN gem install \
        --local fluent-plugin-prometheus-format \
        --local fluent-plugin-kubernetes-sumologic \
        --local fluent-plugin-enhance-k8s-metadata \
        --local fluent-plugin-datapoint \
        --local fluent-plugin-protobuf \
        --local fluent-plugin-events

# Start with fresh image
FROM fluent/fluentd:v1.11.3-debian-1.0

USER root

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
        libsnappy-dev \
        curl \
        jq

# Create directory for Terraform configuration
RUN mkdir -p /terraform /scripts \
 && chown -R fluent:fluent /terraform /scripts

COPY --from=builder /bin/terraform /bin/terraform
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY ./fluent.conf /fluentd/etc/
COPY ./entrypoint.sh /bin/

# Allow installing gems by fluent user
RUN chown fluent /usr/local/bundle/*

USER fluent

COPY --from=builder --chown=fluent:fluent \
    /tmp/terraform/.terraform /terraform/.terraform
