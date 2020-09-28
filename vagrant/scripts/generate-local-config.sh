#!/bin/bash

cat > /sumologic/vagrant/values.local.yaml <<END
image:
  repository: localhost:32000/sumologic/kubernetes-fluentd
  tag: local
  pullPolicy: Always
END
