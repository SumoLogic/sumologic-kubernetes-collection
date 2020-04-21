#Diagnostics

This repository contains a simple tool that allows to check if environment is compatible with
Kubernetes collection.


Running:

`$ kubectl run diag --generator=run-pod/v1 -it --rm --restart=Never --image sumologic/kubernetes-diagnostics --`

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
2020/04/21 17:38:20 Received data for 15 pods in the cluster
pod "diag" deleted
```

The pod can be also run in interactive mode, i.e.:

`$ kubectl run diag --generator=run-pod/v1 -it --rm --restart=Never --image sumologic/kubernetes-diagnostics -- /bin/bash -l`

