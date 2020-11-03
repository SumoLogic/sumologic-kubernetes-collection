# Configuration
To see all available configuration for our sub-charts, please refer to their documentation.

  * [Falco](https://github.com/helm/charts/tree/master/stable/falco#configuration) - All Falco properties should be prefixed with `falco.` in our values.yaml to override a property not listed below.
  * [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#configuration) - All `kube-sprometheus-stack` properties should be prefixed with `prometheus-operator.` in our values.yaml to override a property not listed below.
  * [Fluent-bit](https://github.com/helm/charts/tree/master/stable/fluent-bit#configuration) - All Fluent-bit properties should be prefixed with `fluent-bit.` in our values.yaml to override a property not listed below.
  * [Metrics Server](https://github.com/helm/charts/tree/master/stable/metrics-server#configuration) - All Metrics Server properties should be prefixed with `metrics-server.` in our values.yaml to override a property not listed below.
  
The following table lists the configurable parameters of the Sumo Logic chart and their default values.
  
Parameter | Description | Default
--- | --- | ---
`image.repository`  |   Image repository for Sumo Logic docker container.   |   `sumologic/kubernetes-fluentd`
`image.tag` | Image tag for Sumo Logic docker container. | `1.0.0-rc.2`
`image.pullPolicy` | Image pullPolicy for Sumo Logic docker container.  | `IfNotPresent`
`nameOverride` | Used to override the Chart name. | `Nil`
`sumologic.setupEnabled` | If enabled, a pre-install hook will create Collector and Sources in Sumo Logic. | `true`
`sumologic.logs.enabled` | Set the enabled flag to false for disabling logs ingestion altogether. | `true`
`sumologic.metrics.enabled` | Set the enabled flag to false for disabling metrics ingestion altogether. | `true`
`sumologic.traces.enabled` | Set the enabled flag to true to enable tracing ingestion. _Tracing must be enabled for the account first. Please contact your Sumo representative for activation details_ | `false`
`sumologic.envFromSecret` | If enabled, accessId and accessKey will be sourced from Secret Name given. Be sure to include at least the following env variables in your secret (1) SUMOLOGIC_ACCESSID, (2) SUMOLOGIC_ACCESSKEY | `sumo-api-secret`
`sumologic.accessId` | Sumo access ID. | `Nil`
`sumologic.accessKey` | Sumo access key. | `Nil`
`sumologic.endpoint` | Sumo API endpoint; Leave blank for automatic endpoint discovery and redirection. | `Nil`
`sumologic.collectorName` | The name of the Sumo Logic collector that will be created in the SetUp job.  Defaults to `clusterName` if not specified. | `Nil`
`sumologic.clusterName` | An identifier for the Kubernetes cluster. | `kubernetes`
`sumologic.httpProxy` | HTTP proxy URL | `Nil`
`sumologic.httpsProxy` | HTTPS proxy URL | `Nil`
`sumologic.noProxy` | List of comma separated hostnames which should be excluded from the proxy | `kubernetes.default.svc`
`sumologic.podLabels` | Additional labels for the pods. | `{}`
`sumologic.podAnnotations` | Additional annotations for the pods. | `{}`
`sumologic.scc.create` | Create OpenShift's Security Context Constraint | `false`
`sumologic.setup.clusterRole.annotations` | Annotations for the ClusterRole. | `[{"helm.sh/hook":"pre-install,pre-upgrade","helm.sh/hook-delete-policy":"before-hook-creation,hook-succeeded","helm.sh/hook-weight":"1"}]`
`sumologic.setup.clusterRoleBinding.annotations` | Annotations for the ClusterRole. | `[{"helm.sh/hook":"pre-install,pre-upgrade","helm.sh/hook-delete-policy":"before-hook-creation,hook-succeeded","helm.sh/hook-weight":"2"}]`
`sumologic.setup.configMap"` | Annotations for the ConfigMap. | `[{"helm.sh/hook":"pre-install,pre-upgrade","helm.sh/hook-delete-policy":"before-hook-creation,hook-succeeded","helm.sh/hook-weight":"2"}]`
`sumologic.setup.job.annotations` | Annotations for the Job. | `[{"helm.sh/hook":"pre-install,pre-upgrade","helm.sh/hook-delete-policy":"before-hook-creation,hook-succeeded","helm.sh/hook-weight":"3"}]`
`sumologic.setup.job.podLabels` | Additional labels for the setup Job pod. | `{}`
`sumologic.setup.job.podAnnotations` | Additional annotations for the setup Job pod. | `{}`
`sumologic.setup.serviceAccount.annotations` | Annotations for the ServiceAccount. | `[{"helm.sh/hook":"pre-install,pre-upgrade","helm.sh/hook-delete-policy":"before-hook-creation,hook-succeeded","helm.sh/hook-weight":"0"}]`
`fluentd.additionalPlugins` | Additional Fluentd plugins to install from RubyGems. Please see our [documentation](./Additional_Fluentd_Plugins.md) for more information. | `[]`
`fluentd.compression.enabled` | Flag to control if data is sent to Sumo Logic compressed or not | `true`
`fluentd.compression.encoding` | Specifies which encoding should be use to compress data (either `gzip` or `deflate`) | `gzip`
`fluentd.logLevel` | Sets the fluentd log level. The default log level, if not specified, is info.  Sumo will only ingest the error log level and some specific warnings, the info logs can be seen in kubectl logs. | `info`
`fluentd.verifySsl` | Verify SumoLogic HTTPS certificates. | `true`
`fluentd.proxyUri` | Proxy URI for sumologic output plugin. | `Nil`
`fluentd.securityContext` | the securityContext configuration for Fluentd | `{"fsGroup":999}`
`fluentd.podLabels` | Additional labels for all fluentd pods | `{}`
`fluentd.podAnnotations` | Additional annotations for all fluentd pods | `{}`
`fluentd.podSecurityPolicy.create` | If true, create & use `podSecurityPolicy` for fluentd resources | `false`
`fluentd.persistence.enabled` | Persist data to a persistent volume; When enabled, fluentd uses the file buffer instead of memory buffer. After setting the value to true, run the helm upgrade command with the --force flag. | `false`
`fluentd.persistence.storageClass` | If defined, storageClassName: <storageClass>. If set to "-", storageClassName: "", which disables dynamic provisioning.  If undefined (the default) or set to null, no storageClassName spec is set, choosing the default provisioner.  (gp2 on AWS, standard on GKE, Azure & OpenStack) | `Nil`
`fluentd.persistence.annotations` | Annotations for the persistence. | `Nil`
`fluentd.persistence.accessMode` | The accessMode for persistence. | `ReadWriteOnce`
`fluentd.persistence.size` | The size needed for persistence. | `10Gi`
`fluentd.buffer.type` | Option to specify the Fluentd buffer as file/memory. If `fluentd.persistence.enabled` is `true`, this will be ignored. | `memory`
`fluentd.buffer.flushInterval` | How frequently to push logs to Sumo Logic. | `5s`
`fluentd.buffer.numThreads` | Increase number of http threads to Sumo. May be required in heavy logging/high DPM clusters. | `8`
`fluentd.buffer.chunkLimitSize` | The max size of each chunks: events will be written into chunks until the size of chunks become this size. | `1m`
`fluentd.buffer.queueChunkLimitSize` | Limit the number of queued chunks. | `128`
`fluentd.buffer.totalLimitSize` | The size limitation of this buffer plugin instance. | `128m`
`fluentd.buffer.filePaths` | File paths to buffer to, if Fluentd buffer type is specified as file above. Each sumologic output plugin buffers to its own unique file. | `{"events":"/fluentd/buffer/events","logs":{"containers":"/fluentd/buffer/logs.containers","default":"/fluentd/buffer/logs.default","kubelet":"/fluentd/buffer/logs.kubelet","systemd":"/fluentd/buffer/logs.systemd"},"metrics":{"apiserver":"/fluentd/buffer/metrics.apiserver","container":"/fluentd/buffer/metrics.container","controller":"/fluentd/buffer/metrics.controller","default":"/fluentd/buffer/metrics.default","kubelet":"/fluentd/buffer/metrics.kubelet","node":"/fluentd/buffer/metrics.node","scheduler":"/fluentd/buffer/metrics.scheduler","state":"/fluentd/buffer/metrics.state"},"traces":"/fluentd/buffer/traces"}`
`fluentd.buffer.extraConf` | Additional config for buffer settings | `Nil`
`fluentd.metadata.cacheSize` | Option to control the enabling of metadata filter plugin cache_size. | `10000`
`fluentd.metadata.cacheTtl` | Option to control the enabling of metadata filter plugin cache_ttl (in seconds). | `7200`
`fluentd.metadata.cacheRefresh` | Option to control the interval at which metadata cache is asynchronously refreshed (in seconds). | `3600`
`fluentd.metadata.cacheRefreshVariation` | Option to control the variation in seconds by which the cacheRefresh option is changed for each pod separately. For example, if cache refresh is 1 hour and variation is 15 minutes, then actual cache refresh interval will be a random value between 45 minutes and 1 hour 15 minutes, different for each pod. This helps spread the load on API server that the cache refresh induces. Setting this to 0 disables cache refresh variation. | `900`
`fluentd.metadata.pluginLogLevel` | Option to give plugin specific log level. | `error`
`fluentd.logs.enabled` | Flag to control deploying the Fluentd logs statefulsets. | `true`
`fluentd.logs.statefulset.nodeSelector` | Node selector for Fluentd log statefulset. | `{}`
`fluentd.logs.statefulset.tolerations` | Tolerations for Fluentd log statefulset. | `{}`
`fluentd.logs.statefulset.affinity` | Affinity for Fluentd log statefulset. | `{}`
`fluentd.logs.statefulset.podAntiAffinity` | PodAntiAffinity for Fluentd log statefulset. | `soft`
`fluentd.logs.statefulset.replicaCount` | Replica count for Fluentd log statefulset. | `3`
`fluentd.logs.statefulset.resources` | Resources for Fluentd log statefulset. | `{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.5,"memory":"768Mi"}}`
`fluentd.logs.statefulset.podLabels` | Additional labels for fluentd log pods. | `{}`
`fluentd.logs.statefulset.podAnnotations` | Additional annotations for fluentd log pods. | `{}`
`fluentd.logs.statefulset.priorityClassName` | Priority class name for fluentd log pods. | `Nil`
`fluentd.logs.autoscaling.enabled` | Option to turn autoscaling on for fluentd and specify params for HPA. Autoscaling needs metrics-server to access cpu metrics. | `false`
`fluentd.logs.autoscaling.minReplicas` | Default min replicas for autoscaling. | `3`
`fluentd.logs.autoscaling.maxReplicas` | Default max replicas for autoscaling. | `10`
`fluentd.logs.autoscaling.targetCPUUtilizationPercentage` | The desired target CPU utilization for autoscaling. | `50`
`fluentd.logs.rawConfig` | Default log configuration. | `@include common.conf @include logs.conf`
`fluentd.logs.output.logFormat` | Format to post logs into Sumo: fields, json, json_merge, or text. | `fields`
`fluentd.logs.output.addTimestamp` | Option to control adding timestamp to logs. | `true`
`fluentd.logs.output.timestampKey` | Field name when add_timestamp is on. | `timestamp`
`fluentd.logs.output.pluginLogLevel` | Option to give plugin specific log level. | `error`
`fluentd.logs.output.extraConf` | Additional config parameters for sumologic output plugin | `Nil`
`fluentd.logs.extraLogs` | Additional config for custom log pipelines. | `Nil`
`fluentd.logs.containers.overrideRawConfig` | To override the entire contents of logs.source.containers.conf file. Leave empty for the default pipeline. | `Nil`
`fluentd.logs.containers.outputConf` | Default output configuration for container logs. | `@include logs.output.conf`
`fluentd.logs.containers.overrideOutputConf` | Override output section for container logs. Leave empty for the default output section. | `Nil`
`fluentd.logs.containers.sourceName` | Set the _sourceName metadata field in Sumo Logic. | `%{namespace}.%{pod}.%{container}`
`fluentd.logs.containers.sourceCategory` | Set the _sourceCategory metadata field in Sumo Logic. | `%{namespace}/%{pod_name}`
`fluentd.logs.containers.sourceCategoryPrefix` | Set the prefix, for _sourceCategory metadata. | `kubernetes/`
`fluentd.logs.containers.sourceCategoryReplaceDash` | Used to replace - with another character. | `/`
`fluentd.logs.containers.excludeContainerRegex` | A regular expression for containers. Matching containers will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.containers.excludeHostRegex` | A regular expression for hosts. Matching hosts will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.containers.excludeNamespaceRegex` | A regular expression for namespaces. Matching namespaces will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.containers.excludePodRegex` | A regular expression for pods. Matching pods will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.containers.k8sMetadataFilter.watch` | Option to control the enabling of metadata filter plugin watch. | `true`
`fluentd.logs.containers.k8sMetadataFilter.caFile` | path to CA file for Kubernetes server certificate validation. | `Nil`
`fluentd.logs.containers.k8sMetadataFilter.verifySsl` | Validate SSL certificates. | `true`
`fluentd.logs.containers.k8sMetadataFilter.clientCert` | Path to a client cert file to authenticate to the API server. | `Nil`
`fluentd.logs.containers.k8sMetadataFilter.clientKey` | Path to a client key file to authenticate to the API server. | `Nil`
`fluentd.logs.containers.k8sMetadataFilter.bearerTokenFile` | Path to a file containing the bearer token to use for authentication. | `Nil`
`fluentd.logs.containers.extraFilterPluginConf` | To use additional filter plugins. | `Nil`
`fluentd.logs.kubelet.enabled` | Collect kubelet logs. | `true`
`fluentd.logs.kubelet.outputConf` | Output configuration for kubelet. | `@include logs.output.conf`
`fluentd.logs.kubelet.overrideOutputConf` | Override output section for kubelet logs. Leave empty for the default output section. | `Nil`
`fluentd.logs.kubelet.sourceName` | Set the _sourceName metadata field in Sumo Logic. | `k8s_kubelet`
`fluentd.logs.kubelet.sourceCategory` | Set the _sourceCategory metadata field in Sumo Logic. | `kubelet`
`fluentd.logs.kubelet.sourceCategoryPrefix` | Set the prefix, for _sourceCategory metadata. | `kubernetes/`
`fluentd.logs.kubelet.sourceCategoryReplaceDash` | Used to replace - with another character. | `/`
`fluentd.logs.kubelet.excludeFacilityRegex` | A regular expression for facility. Matching facility will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.kubelet.excludeHostRegex` | A regular expression for hosts. Matching hosts will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.kubelet.excludePriorityRegex` | A regular expression for priority. Matching priority will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.kubelet.excludeUnitRegex` | A regular expression for unit. Matching unit will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.systemd.enabled` | Collect systemd logs. | `true`
`fluentd.logs.systemd.outputConf` | Output configuration for systemd. | `@include logs.output.conf`
`fluentd.logs.systemd.overrideOutputConf` | Override output section for systemd logs. Leave empty for the default output section. | `Nil`
`fluentd.logs.systemd.sourceCategory` | Set the _sourceCategory metadata field in Sumo Logic. | `system`
`fluentd.logs.systemd.sourceCategoryPrefix` | Set the prefix, for _sourceCategory metadata. | `kubernetes/`
`fluentd.logs.systemd.sourceCategoryReplaceDash` | Used to replace - with another character. | `/`
`fluentd.logs.systemd.excludeFacilityRegex` | A regular expression for facility. Matching facility will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.systemd.excludeHostRegex` | A regular expression for hosts. Matching hosts will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.systemd.excludePriorityRegex` | A regular expression for priority. Matching priority will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.systemd.excludeUnitRegex` | A regular expression for unit. Matching unit will be excluded from Sumo. The logs will still be sent to FluentD. | `Nil`
`fluentd.logs.default.outputConf` | Default log configuration (catch-all). | `@include logs.output.conf`
`fluentd.logs.default.overrideOutputConf` | Override output section for untagged logs. Leave empty for the default output section. | `Nil`
`fluentd.metrics.enabled` | Flag to control deploying the Fluentd metrics statefulsets. | `true`
`fluentd.metrics.statefulset.nodeSelector` | Node selector for Fluentd metrics statefulset. | `{}`
`fluentd.metrics.statefulset.tolerations` | Tolerations for Fluentd metrics statefulset. | `{}`
`fluentd.metrics.statefulset.affinity` | Affinity for Fluentd metrics statefulset. | `{}`
`fluentd.metrics.statefulset.podAntiAffinity` | PodAntiAffinity for Fluentd metrics statefulset. | `soft`
`fluentd.metrics.statefulset.replicaCount` | Replica count for Fluentd metrics statefulset. | `3`
`fluentd.metrics.statefulset.resources` | Resources for Fluentd metrics statefulset.  | `{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.5,"memory":"768Mi"}}`
`fluentd.metrics.statefulset.podLabels` | Additional labels for fluentd metrics pods. | `{}`
`fluentd.metrics.statefulset.podAnnotations` | Additional annotations for fluentd metrics pods. | `{}`
`fluentd.logs.statefulset.priorityClassName` | Priority class name for fluentd metrics pods. | `Nil`
`fluentd.metrics.autoscaling.enabled` | Option to turn autoscaling on for fluentd and specify params for HPA. Autoscaling needs metrics-server to access cpu metrics. | `false`
`fluentd.metrics.autoscaling.minReplicas` | Default min replicas for autoscaling. | `3`
`fluentd.metrics.autoscaling.maxReplicas` | Default max replicas for autoscaling. | `10`
`fluentd.metrics.autoscaling.targetCPUUtilizationPercentage` | The desired target CPU utilization for autoscaling. | `50`
`fluentd.metrics.rawConfig` | Raw config for fluentd metrics. | `@include common.conf @include metrics.conf`
`fluentd.metrics.outputConf` | Configuration for sumologic output plugin. | `@include metrics.output.conf`
`fluentd.metrics.extraFilterPluginConf` | To use additional filter plugins. | `Nil`
`fluentd.metrics.extraOutputPluginConf` | To use additional output plugins. | `Nil`
`fluentd.events.enabled` | If enabled, collect K8s events. | `true`
`fluentd.events.statefulset.nodeSelector` | Node selector for Fluentd events statefulset. | `{}`
`fluentd.events.statefulset.tolerations` | Tolerations for Fluentd events statefulset. | `{}`
`fluentd.events.statefulset.resources` | Resources for Fluentd log statefulset. | `{"limits":{"cpu":"100m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}`
`fluentd.events.statefulset.podLabels` | Additional labels for fluentd events pods. | `{}`
`fluentd.events.statefulset.podAnnotations` | Additional annotations for fluentd events pods. | `{}`
`fluentd.events.statefulset.priorityClassName` | Priority class name for fluentd events pods. | `Nil`
`fluentd.events.sourceCategory` | Source category for the Events source. Default: "{clusterName}/events" | `Nil`
`metrics-server.enabled` | Set the enabled flag to true for enabling metrics-server. This is required before enabling fluentd autoscaling unless you have an existing metrics-server in the cluster. | `false`
`metrics-server.args` | Arguments for metric server. | `["--kubelet-insecure-tls","--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"]`
`fluent-bit.resources` | Resources for Fluent-bit daemonsets. | `{}`
`fluent-bit.enabled` | Flag to control deploying Fluent-bit Helm sub-chart. | `true`
`fluent-bit.podLabels` | Additional labels for fluent-bit pods. | `{}`
`fluent-bit.podAnnotations` | Additional annotations for fluent-bit pods. | `{}`
`fluent-bit.service.flush` | Frequency to flush fluent-bit buffer to fluentd. | `5`
`fluent-bit.metrics.enabled` | Enable metrics from fluent-bit. | `true`
`fluent-bit.env` | Environment variables for fluent-bit. | `[{"name":"CHART","valueFrom":{"configMapKeyRef":{"key":"fluentdLogs","name":"sumologic-configmap"}}},{"name":"NAMESPACE","valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}}]`
`fluent-bit.backend.type` | Set the backend to which Fluent-Bit should flush the information it gathers | `forward`
`fluent-bit.backend.forward.host` | Target host where Fluent-Bit or Fluentd are listening for Forward messages. | `${CHART}.${NAMESPACE}.svc.cluster.local.`
`fluent-bit.backend.forward.port` | TCP Port of the target service. | `24321`
`fluent-bit.backend.forward.tls` | Enable or disable TLS support. | `off`
`fluent-bit.backend.forward.tls_verify` | Force certificate validation. | `on`
`fluent-bit.backend.forward.tls_debug` | Set TLS debug verbosity level. It accept the following values: 0-4. | `1`
`fluent-bit.backend.forward.shared_key` | A key string known by the remote Fluentd used for authorization. | `Nil`
`fluent-bit.trackOffsets` | Specify whether to track the file offsets for tailing docker logs. This allows fluent-bit to pick up where it left after pod restarts but requires access to a hostPath. | `true`
`fluent-bit.tolerations` | Optional daemonset tolerations. | `[{"effect":"NoSchedule","operator":"Exists"}]`
`fluent-bit.input.systemd.enabled` | Enable systemd input. | `true`
`fluent-bit.parsers.enabled` | Enable custom parsers. | `true`
`fluent-bit.parsers.regex` | List of regex parsers. | `[{"name":"multi_line","regex":"(?\u003clog\u003e^{\"log\":\"\\d{4}-\\d{1,2}-\\d{1,2}.\\d{2}:\\d{2}:\\d{2}.*)"}]`
`fluent-bit.rawConfig` | DESCRIPTION | `@INCLUDE fluent-bit-service.conf [INPUT] Name tail Path /var/log/containers/*.log Multiline On Parser_Firstline multi_line Tag containers.* Refresh_Interval 1 Rotate_Wait 60 Mem_Buf_Limit 5MB Skip_Long_Lines On DB /tail-db/tail-containers-state-sumo.db DB.Sync Normal [INPUT] Name systemd Tag host.* Systemd_Filter _SYSTEMD_UNIT=addon-config.service Systemd_Filter _SYSTEMD_UNIT=addon-run.service Systemd_Filter _SYSTEMD_UNIT=cfn-etcd-environment.service Systemd_Filter _SYSTEMD_UNIT=cfn-signal.service Systemd_Filter _SYSTEMD_UNIT=clean-ca-certificates.service Systemd_Filter _SYSTEMD_UNIT=containerd.service Systemd_Filter _SYSTEMD_UNIT=coreos-metadata.service Systemd_Filter _SYSTEMD_UNIT=coreos-setup-environment.service Systemd_Filter _SYSTEMD_UNIT=coreos-tmpfiles.service Systemd_Filter _SYSTEMD_UNIT=dbus.service Systemd_Filter _SYSTEMD_UNIT=docker.service Systemd_Filter _SYSTEMD_UNIT=efs.service Systemd_Filter _SYSTEMD_UNIT=etcd-member.service Systemd_Filter _SYSTEMD_UNIT=etcd.service Systemd_Filter _SYSTEMD_UNIT=etcd2.service Systemd_Filter _SYSTEMD_UNIT=etcd3.service Systemd_Filter _SYSTEMD_UNIT=etcdadm-check.service Systemd_Filter _SYSTEMD_UNIT=etcdadm-reconfigure.service Systemd_Filter _SYSTEMD_UNIT=etcdadm-save.service Systemd_Filter _SYSTEMD_UNIT=etcdadm-update-status.service Systemd_Filter _SYSTEMD_UNIT=flanneld.service Systemd_Filter _SYSTEMD_UNIT=format-etcd2-volume.service Systemd_Filter _SYSTEMD_UNIT=kube-node-taint-and-uncordon.service Systemd_Filter _SYSTEMD_UNIT=kubelet.service Systemd_Filter _SYSTEMD_UNIT=ldconfig.service Systemd_Filter _SYSTEMD_UNIT=locksmithd.service Systemd_Filter _SYSTEMD_UNIT=logrotate.service Systemd_Filter _SYSTEMD_UNIT=lvm2-monitor.service Systemd_Filter _SYSTEMD_UNIT=mdmon.service Systemd_Filter _SYSTEMD_UNIT=nfs-idmapd.service Systemd_Filter _SYSTEMD_UNIT=nfs-mountd.service Systemd_Filter _SYSTEMD_UNIT=nfs-server.service Systemd_Filter _SYSTEMD_UNIT=nfs-utils.service Systemd_Filter _SYSTEMD_UNIT=node-problem-detector.service Systemd_Filter _SYSTEMD_UNIT=ntp.service Systemd_Filter _SYSTEMD_UNIT=oem-cloudinit.service Systemd_Filter _SYSTEMD_UNIT=rkt-gc.service Systemd_Filter _SYSTEMD_UNIT=rkt-metadata.service Systemd_Filter _SYSTEMD_UNIT=rpc-idmapd.service Systemd_Filter _SYSTEMD_UNIT=rpc-mountd.service Systemd_Filter _SYSTEMD_UNIT=rpc-statd.service Systemd_Filter _SYSTEMD_UNIT=rpcbind.service Systemd_Filter _SYSTEMD_UNIT=set-aws-environment.service Systemd_Filter _SYSTEMD_UNIT=system-cloudinit.service Systemd_Filter _SYSTEMD_UNIT=systemd-timesyncd.service Systemd_Filter _SYSTEMD_UNIT=update-ca-certificates.service Systemd_Filter _SYSTEMD_UNIT=user-cloudinit.service Systemd_Filter _SYSTEMD_UNIT=var-lib-etcd2.service Max_Entries 1000 Read_From_Tail true @INCLUDE fluent-bit-output.conf`
`prometheus-operator.kubeTargetVersionOverride` | Provide a target gitVersion of K8S, in case .Capabilites.KubeVersion is not available (e.g. helm template). Changing this may break Sumo Logic apps. | `1.13.0-0`
`prometheus-operator.enabled` | Flag to control deploying Prometheus Operator Helm sub-chart. | `true`
`prometheus-operator.alertmanager.enabled` | Deploy alertmanager. | `false`
`prometheus-operator.grafana.enabled` | If true, deploy the grafana sub-chart. | `false`
`prometheus-operator.grafana.defaultDashboardsEnabled` | Deploy default dashboards. These are loaded using the sidecar. | `false`
`prometheus-operator.prometheusOperator.podLabels` | Additional labels for prometheus operator pods. | `{}`
`prometheus-operator.prometheusOperator.podAnnotations` | Additional annotations for prometheus operator pods. | `{}`
`prometheus-operator.prometheusOperator.resources` | Resource limits for prometheus operator.  Uses sub-chart defaults. | `{}`
`prometheus-operator.prometheusOperator.admissionWebhooks.enabled` | Create PrometheusRules admission webhooks. Mutating webhook will patch PrometheusRules objects indicating they were validated. Validating webhook will check the rules syntax. | `false`
`prometheus-operator.prometheusOperator.tlsProxy.enabled` | Enable a TLS proxy container. Only the squareup/ghostunnel command line arguments are currently supported and the secret where the cert is loaded from is expected to be provided by the admission webhook. | `false`
`prometheus-operator.kube-state-metrics.resources` | Resource limits for kube state metrics.  Uses sub-chart defaults. | `{}`
`prometheus-operator.kube-state-metrics.customLabels` | Custom labels to apply to service, deployment and pods.  Uses sub-chart defaults. | `{}`
 `prometheus-operator.kube-state-metrics.podAnnotations` | Additional annotations for pods in the DaemonSet.  Uses sub-chart defaults. | `{}`
`prometheus-operator.prometheus.additionalServiceMonitors` | List of ServiceMonitor objects to create. | `[{"additionalLabels":{"app":"collection-sumologic-fluentd-logs"},"endpoints":[{"port":"metrics"}],"name":"collection-sumologic-fluentd-logs","namespaceSelector":{"matchNames":["sumologic"]},"selector":{"matchLabels":{"app":"collection-sumologic-fluentd-logs"}}},{"additionalLabels":{"app":"collection-sumologic-fluentd-metrics"},"endpoints":[{"port":"metrics"}],"name":"collection-sumologic-fluentd-metrics","namespaceSelector":{"matchNames":["sumologic"]},"selector":{"matchLabels":{"app":"collection-sumologic-fluentd-metrics"}}},{"additionalLabels":{"app":"collection-sumologic-fluentd-events"},"endpoints":[{"port":"metrics"}],"name":"collection-sumologic-fluentd-events","namespaceSelector":{"matchNames":["sumologic"]},"selector":{"matchLabels":{"app":"collection-sumologic-fluentd-events"}}},{"additionalLabels":{"app":"collection-fluent-bit"},"endpoints":[{"path":"/api/v1/metrics/prometheus","port":"metrics"}],"name":"collection-fluent-bit","namespaceSelector":{"matchNames":["sumologic"]},"selector":{"matchLabels":{"app":"fluent-bit"}}},{"additionalLabels":{"app":"collection-sumologic-otelcol"},"endpoints":[{"port":"metrics"}],"name":"collection-sumologic-otelcol","namespaceSelector":{"matchNames":["sumologic"]},"selector":{"matchLabels":{"app":"collection-sumologic-otelcol"}}}]`
`prometheus-operator.prometheus.prometheusSpec.resources` | Resource limits for prometheus.  Uses sub-chart defaults. | `{}`
`prometheus-operator.prometheus.prometheusSpec.thanos.baseImage` | Base image for Thanos container. | `quay.io/thanos/thanos`
`prometheus-operator.prometheus.prometheusSpec.thanos.version` | Image tag for Thanos container. | `v0.10.0`
`prometheus-operator.prometheus.prometheusSpec.containers` | Containers allows injecting additional containers. This is meant to allow adding an authentication proxy to a Prometheus pod. | `[{"env":[{"name":"CHART","valueFrom":{"configMapKeyRef":{"key":"fluentdMetrics","name":"sumologic-configmap"}}},{"name":"NAMESPACE","valueFrom":{"configMapKeyRef":{"key":"fluentdNamespace","name":"sumologic-configmap"}}}],"name":"prometheus-config-reloader"}]`
`prometheus-operator.prometheus.prometheusSpec.podMetadata.labels` | Add custom pod labels to prometheus pods | `{}`
`prometheus-operator.prometheus.prometheusSpec.podMetadata.annotations` | Add custom pod annotations to prometheus pods | `{}`
`prometheus-operator.prometheus.prometheusSpec.remoteWrite` | If specified, the remote_write spec. | See values.yaml
`prometheus-operator.prometheus.prometheusSpec.walCompression` | Enables walCompression in Prometheus | `true`
`prometheus-operator.prometheus-node-exporter.podLabels` | Additional labels for prometheus-node-exporter pods. | `{}`
`prometheus-operator.prometheus-node-exporter.podAnnotations` | Additional annotations for prometheus-node-exporter pods. | `{}`
`prometheus-operator.prometheus-node-exporter.resources` | Resource limits for node exporter.  Uses sub-chart defaults. | `{}`
`falco.enabled` | Flag to control deploying Falco Helm sub-chart. | `false`
`falco.ebpf.enabled` | Enable eBPF support for Falco instead of falco-probe kernel module. Set to false for GKE. | `true`
`falco.falco.jsonOutput` | Output events in json. | `true`
`telegraf-operator.enabled` | Flag to control deploying Telegraf Operator Helm sub-chart. | `false`
`telegraf-operator.replicaCount` | Replica count for Telegraf Operator pods. | 1
`telegraf-operator.classes.secretName` | Secret name in which the Telegraf Operator configuration will be stored. | `telegraf-operator-classes`
`telegraf-operator.default` | Name of the default output configuration. | `sumologic-prometheus`
`telegraf-operator.data` | Telegraf sidecar configuration. | `{"sumologic-prometheus": "[[outputs.prometheus_client]]\\n          ## Configuration details:\\n          ## https://github.com/influxdata/telegraf/tree/master/plugins/outputs/prometheus_client#configuration\\n          listen = ':9273'\\n          metric_version = 2\\n"}`
`otelcol.deployment.replicas` | Set the number of OpenTelemetry Collector replicas. | `1`
`otelcol.deployment.resources.limits.memory` | Sets the OpenTelemetry Collector memory limit. | `2Gi`
`otelcol.deployment.priorityClassName` | Priority class name for OpenTelemetry Collector log pods. | `Nil`
`otelcol.metrics.enabled` | Enable or disable generation of the metrics from Collector. | `false`
`otelcol.config.service.pipelines.traces.receivers` | Sets the list of enabled receivers. | `{jaeger, opencensus, otlp, zipkin}`
`otelcol.config.exporters.zipkin.timeout` | Sets the Zipkin (default) exporter timeout. Append the unit, e.g. `s` when setting the parameter | `5s`
`otelcol.config.exporters.logging.loglevel` | When tracing debug logging exporter is enabled, sets the verbosity level. Use either `info` or `debug`. | `info`
`otelcol.config.service.pipelines.traces.exporters` | Sets the list of exporters enabled within OpenTelemetry Collector. Available values: `zipkin`, `logging`. Set to `{zipkin, logging}` to enable logging debugging exporter. | `{zipkin}` 
`otelcol.config.service.pipelines.traces.processors` | Sets the list of enabled OpenTelemetry Collector processors. | `{memory_limiter, k8s_tagger, source, resource, batch, queued_retry}`
`otelcol.config.processors.memory_limiter.limit_mib` | Sets the OpenTelemetry Collector memory limitter plugin value (in MiB). Should be at least 100 Mib less than the value of `otelcol.deployment.resources.limits.memory`.  | `1900` 
`otelcol.config.processors.batch.send_batch_size` | Sets the preferred size of batch (in number of spans). | `256`
`otelcol.config.processors.batch.send_batch_max_size` | Sets the maximum allowed size of a batch (in number of spans). Use with caution, setting too large value might cause 413 Payload Too Large errors. | `512`
