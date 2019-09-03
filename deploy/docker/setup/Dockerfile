FROM alpine:3.9

RUN apk add --no-cache gnupg
RUN apk add --no-cache curl
RUN apk add --no-cache jq

# Install kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v1.6.12/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

COPY setup.sh /usr/bin/
