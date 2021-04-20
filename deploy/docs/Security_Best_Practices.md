# Advanced Configuration / Security Best Practices

- [Hardening fluentd StatefulSet with `securityContext`](#hardening-fluentd-statefulset-with-securitycontext)

## Hardening fluentd StatefulSet with `securityContext`

One can use `fluentd.securityContext` and
`fluentd.(logs|metrics|events).statefulset.containers.fluentd.securityContext`
to tighten up the security requirements for fluentd containers running as part
of collection StatefulSets.

One example of such a configuration can be found below:

```yaml
fluentd:
  ...
  securityContext:
    ## The group ID of all processes in the statefulset containers.
    ## By default this needs to be fluent(999).
    fsGroup: 999
    runAsNonRoot: true
  logs:
    enabled: true
    ...
    statefulset:
      containers:
        fluentd:
          securityContext:
            runAsNonRoot: true
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
    extraVolumeMounts:
      - mountPath: /tmp/
        name: tmp-volume-logs
    extraVolumes:
      - emptyDir: {}
        name: tmp-volume-logs
  metrics:
    ...
```
