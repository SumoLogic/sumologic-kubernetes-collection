FROM golang:1.14.1 as builder
RUN mkdir /build
ADD src /build/
WORKDIR /build
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o k8s-api-test cmd/k8s-api-test/main.go

FROM alpine:3.9

RUN set -ex \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
    bash \
    busybox-extras \
    curl \
    libc6-compat \
    openssl \
    net-tools \
    vim \
    wget

ENV HELM_VERSION="v3.2.0"
RUN wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

ADD motd /etc/motd
ADD profile  /etc/profile

ADD check /usr/bin/check
ADD tools-usage /usr/bin/tools-usage
ADD template /usr/bin/template
COPY --from=builder /build/k8s-api-test /usr/bin/

CMD ["/usr/bin/tools-usage"]