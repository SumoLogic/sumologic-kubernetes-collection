# Windows support

Windows support is under evaluation and is experimental. This document describes issues which should be resolved before claiming full
support for windows.

## Running collection on windows nodes

In order to fully support windows nodes, the following issues should be addressed:

- Windows nodes do not support linux filesystems
- We should use HostProcess Containers to support log collection
- Lack of windows supported containers

### Known Issues

If pod stuck in Container Creating state, and shows the following error:

```text
Warning  FailedCreatePodSandBox  4s (x2 over 18s)  kubelet            (combined from similar events): Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "6b7584ff75fd07362dd40aa18319998ae6f2b0afb78a391d773c953a17216c55": plugin type="vpc-bridge" name="vpc" failed (add): failed to parse Kubernetes args: failed to get pod IP address collection-sumologic-otelcol-logs-2: error executing k8s connector: error executing connector binary: exit status 1 with execution error: pod collection-sumologic-otelcol-logs-2 does not have label vpc.amazonaws.com/PrivateIPv4Address
```

You need to add the following resource configuration:

```yaml
resources:
  limits:
    vpc.amazonaws.com/PrivateIPv4Address: 1
  requests:
    vpc.amazonaws.com/PrivateIPv4Address: 1
```
