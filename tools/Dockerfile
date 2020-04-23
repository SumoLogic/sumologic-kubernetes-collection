FROM golang:1.14.1 as builder
RUN mkdir /build
ADD . /build/
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
    vim

ADD motd /etc/motd
ADD profile  /etc/profile

ADD k8s-check.sh /usr/bin/k8s-check.sh
ADD usage.sh /usr/bin/usage.sh
COPY --from=builder /build/k8s-api-test /usr/bin/

CMD ["/usr/bin/usage.sh"]