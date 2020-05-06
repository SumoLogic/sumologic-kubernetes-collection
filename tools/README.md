#Tools

This repository contains a simple tool that allows to check if environment is compatible with
Kubernetes collection.


# Running

## K8S Check

When Sumo Logic Kubernetes Collection is installed already:

`$ kubectl run tools --generator=run-pod/v1 -it --rm --restart=Never -n sumologic --serviceaccount='collection-sumologic' --image sumologic/kubernetes-tools -- check`

Alternatively, when collection is not installed, the same command can be run for default serviceaccount:

`$ kubectl run tools --generator=run-pod/v1 -it --rm --restart=Never --image sumologic/kubernetes-tools -- check`

Should provide an output such as:

```
/var/run/secrets/kubernetes.io/serviceaccount/token exists, size=842
/var/run/secrets/kubernetes.io/serviceaccount/ca.crt exists, size=1025
/var/run/secrets/kubernetes.io/serviceaccount/namespace exists, size=7
/var/run/secrets/kubernetes.io/serviceaccount/namespace contents: default
KUBERNETES_SERVICE_HOST is set
KUBERNETES_SERVICE_PORT is set
POD_NAMESPACE is not set
POD_NAMESPACE env variable:
Kubernetes cluster at 10.96.0.1:443
Running K8S API test
2020/04/21 18:51:45 Kubernetes version: v1.15.5
2020/04/21 18:51:45 Received data for 15 pods in the cluster
pod "diag" deleted
```

## Trace stress-tester

There's a simple tool that generates a desired number of spans per minute and sends them using Jaeger format

```
 kubectl run stress-tester --generator=run-pod/v1 -it --rm --restart=Never -n sumologic \
  --image sumologic/kubernetes-tools \
  --serviceaccount='collection-sumologic' \
  --env JAEGER_AGENT_HOST=collection-sumologic-otelcol.sumologic \
  --env JAEGER_AGENT_PORT=6831 \
  --env TOTAL_SPANS=1000000 \
  --env SPANS_PER_MIN=6000 --
```

You can set Jaeger Go client env variables (such as `JAEGER_AGENT_HOST` or `JAEGER_COLLECTOR`) and stress-tester specific ones:

* `TOTAL_SPANS` (default=10000000) - total number of spans to generate
* `SPANS_PER_MIN` (required) - rate of spans per minute (the tester will adjust the delay between iterations to reach such rate)


## Interactive mode

The pod can be also run in interactive mode:

`$ kubectl run tools --generator=run-pod/v1 -it --rm --restart=Never --image sumologic/kubernetes-tools -- /bin/bash -l`

