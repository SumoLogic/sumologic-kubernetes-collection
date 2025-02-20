# Windows support

Windows support is under evaluation and is experimental. This document describes issues which should be resolved before claiming full
support for windows.

## Running collection on windows nodes

- To setup a k8s cluster with windows nodes, here's a terraform registry for reference:
  - https://registry.terraform.io/modules/aws-samples/windows-workloads-on-aws/aws/latest/submodules/eks-windows

- It is a known limitation that windows nodes only support the containerd runtime:
  - https://kubernetes.io/docs/concepts/windows/intro/#containerd

- We need the Windows nodes to use containerd 1.7.1 or greater to keep linux mounts for Windows hosts
  - https://kubernetes.io/docs/tasks/configure-pod-container/create-hostprocess-pod/#containerd-v1-7-and-greater
  - PR: https://github.com/containerd/containerd/pull/8331

- The logs collection container (and possibly others) must be HostProcess containers for privileged access on the Windows node
  - https://kubernetes.io/docs/tasks/configure-pod-container/create-hostprocess-pod/#hostprocess-pod-configuration-requirements

- The templates for the metadata enrichment should be very similar for both linux and windows nodes
  - If possible we might want to continue running the metadata enrichment on linux nodes
  - Only pods responsible for collecting the signals, run on both windows and linux nodes

- The windows container base images we would use are mentioned below
  - https://hub.docker.com/r/microsoft/windows-nanoserver

- Hardware recommendations for Windows containers
  - https://kubernetes.io/docs/concepts/windows/intro/#windows-hardware-recommendations

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
