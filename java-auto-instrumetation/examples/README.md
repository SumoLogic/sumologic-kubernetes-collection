# Introduction
This directory contains some examples and auxiliary resources that can be
helpful in deploying and debugging the operator

## Update operator image
I'm assuming here that the operator was deployed by `operator.yaml`:
```shell script
kubectl -n your-namespace set image deployments/java-auto-instrumetation java-auto-instrumetation=quay.io/pioter/java-auto-instrumentation-operator:v0.5
```
