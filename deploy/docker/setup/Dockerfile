FROM alpine:3

ENV TERRAFORM_VERSION 0.12.25-r0

RUN apk update \
 && apk add --no-cache \
        bash \
        curl \
        jq \
        terraform=${TERRAFORM_VERSION} \
 # ping group has a conflicting id: 999 so delete it
 && delgroup ping \
 && addgroup -g 999 setup \
 && adduser -u 999 -D -G setup setup \
 && mkdir /terraform /scripts \
 && chown -R setup:setup /terraform /scripts

# main.tf is copied from ../../helm/sumologic/conf/setup/setup.sh to minimize
# docker context just to current directory
COPY --chown=setup:setup ./main.tf /terraform/

USER setup
RUN cd /terraform/ \
 && terraform init \
 && rm main.tf

ARG BUILD_TAG=latest
ENV TAG $BUILD_TAG

WORKDIR /terraform/
