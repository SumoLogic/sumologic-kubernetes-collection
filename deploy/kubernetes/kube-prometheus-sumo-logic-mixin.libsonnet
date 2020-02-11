{
  _config+:: {
    sumologicCollectorSvc: 'http://collection-sumologic.sumologic.svc.cluster.local:9888/',
    clusterName: "kubernetes"
  },
  sumologicCollector:: {
    remoteWriteConfigs+: ,
  },
  prometheus+:: {
    prometheus+: {
      spec+: {
        remoteWrite+: $.sumologicCollector.remoteWriteConfigs,
        externalLabels+: {
          cluster: $._config.clusterName,
        },
      },
    },
  },
}
