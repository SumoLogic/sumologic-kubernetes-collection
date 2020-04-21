#Diagnostics

This repository contains a simple tool that allows to check if environment is compatible with
Kubernetes collection.


Running:

`$ kubectl run diag --generator=run-pod/v1 -it --rm --restart=Never --image localhost:5000/diagnostics --`

Should provide an output such as:

```
/var/run/secrets/kubernetes.io/serviceaccount/token exists, size=842B
/var/run/secrets/kubernetes.io/serviceaccount/ca.crt exists, size=1025B
/var/run/secrets/kubernetes.io/serviceaccount/namespace exists, size=7B
KUBERNETES_SERVICE_HOST is set
KUBERNETES_SERVICE_PORT is set
POD_NAMESPACE is not set
Kubernetes cluster at 10.96.0.1:443
Pod namespace env variable:
Running K8S API test
2020/04/21 17:08:19 Received data for 15 pods in the cluster
pod "diag" deleted
```

The pod can be also run in interactive mode, i.e.:

`$ kubectl run diag --generator=run-pod/v1 -it --rm --restart=Never --image sumologic/k8s-diagnostics -- /bin/bash -l`

