{{/*
Check if any metrics provider is enabled
Example Usage:
{{- if eq (include "metrics.enabled" .) "true" }}

*/}}
{{- define "metrics.enabled" -}}
{{- $enabled := false -}}
{{- if eq (include "metrics.otelcol.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{- if eq (include "metrics.fluentd.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{ $enabled }}
{{- end -}}


{{/*
Check if otelcol metrics provider is enabled
Example Usage:
{{- if eq (include "metrics.otelcol.enabled" .) "true" }}

*/}}
{{- define "metrics.otelcol.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.metrics.enabled true -}}
{{- if and (eq .Values.sumologic.metrics.metadata.provider "otelcol") (eq .Values.metadata.metrics.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}


{{/*
Check if fluentd metrics provider is enabled
Example Usage:
{{- if eq (include "metrics.fluentd.enabled" .) "true" }}

*/}}
{{- define "metrics.fluentd.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.metrics.enabled true -}}
{{- if and (eq .Values.sumologic.metrics.metadata.provider "fluentd") (eq .Values.fluentd.metrics.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Generate list of remoteWrite endpoints for telegraf configuration

'{{ include "metric.endpoints" . }}'
*/}}
{{- define "metric.endpoints" -}}
{{- $endpoints := list -}}
{{- $kps := get .Values "kube-prometheus-stack" -}}
{{- range $remoteWrite := $kps.prometheus.prometheusSpec.remoteWrite }}
{{- $endpoints = append $endpoints ($remoteWrite.url | trimPrefix "http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888" | quote) -}}
{{- end }}
{{- range $remoteWrite := $kps.prometheus.prometheusSpec.additionalRemoteWrite }}
{{- $endpoints = append $endpoints ($remoteWrite.url | trimPrefix "http://$(METADATA_METRICS_SVC).$(NAMESPACE).svc.cluster.local.:9888" | quote) -}}
{{- end -}}
{{- range $endpoint := .Values.metadata.metrics.config.additionalEndpoints }}
{{- $endpoints = append $endpoints ($endpoint | quote) -}}
{{- end -}}
{{- $endpoints := uniq $endpoints -}}
{{- $endpoints := sortAlpha $endpoints -}}
{{ $endpoints | join ",\n" }}
{{- end -}}

{{/*
Check if remote write proxy is enabled.
Example Usage:
{{- if eq (include "metrics.remoteWriteProxy.enabled" .) "true" }}

*/}}
{{- define "metrics.remoteWriteProxy.enabled" -}}
{{ and (eq (include "metrics.enabled" .) "true") (eq .Values.sumologic.metrics.remoteWriteProxy.enabled true) }}
{{- end -}}

{{- define "sumologic.labels.app.metrics" -}}
{{- if eq .Values.sumologic.metrics.metadata.provider "fluentd" -}}
{{ template "sumologic.labels.app.fluentd" . }}-metrics
{{- else if eq .Values.sumologic.metrics.metadata.provider "otelcol" -}}
{{ template "sumologic.labels.app.otelcol" . }}-metrics
{{- end -}}
{{- end -}}

{{- define "sumologic.labels.app.metrics.pod" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.service" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.service-headless" -}}
{{- template "sumologic.labels.app.metrics.service" . }}-headless
{{- end -}}

{{- define "sumologic.labels.app.metrics.configmap" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.statefulset" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.metrics.hpa" -}}
{{- template "sumologic.labels.app.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy" -}}
{{- template "sumologic.fullname" . }}-remote-write-proxy
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.configmap" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.deployment" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.pod" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.app.remoteWriteProxy.service" -}}
{{- template "sumologic.labels.app.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics" -}}
{{- if eq .Values.sumologic.metrics.metadata.provider "fluentd" -}}
{{ template "sumologic.metadata.name.fluentd" . }}-metrics
{{- else if eq .Values.sumologic.metrics.metadata.provider "otelcol" -}}
{{ template "sumologic.metadata.name.otelcol" . }}-metrics
{{- end -}}
{{- end -}}

{{- define "sumologic.metrics.metadata.endpoint" -}}
{{- if .Values.sumologic.metrics.remoteWriteProxy.enabled -}}
{{ template "sumologic.metadata.name.remoteWriteProxy.service" . }}
{{- else -}}
{{ template "sumologic.metadata.name.metrics.service" . }}
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.service" -}}
{{ template "sumologic.fullname" . }}-metadata-metrics
{{- end -}}

{{- define "sumologic.metadata.name.metrics.service-headless" -}}
{{ template "sumologic.metadata.name.metrics" . }}-headless
{{- end -}}

{{- define "sumologic.metadata.name.metrics.configmap" -}}
{{ template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.statefulset" -}}
{{ template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.pdb" -}}
{{ template "sumologic.metadata.name.metrics.statefulset" . }}-pdb
{{- end -}}

{{- define "sumologic.metadata.name.metrics.hpa" -}}
{{- template "sumologic.metadata.name.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy" -}}
{{ template "sumologic.fullname" . }}-remote-write-proxy
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy.configmap" -}}
{{ template "sumologic.metadata.name.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy.deployment" -}}
{{ template "sumologic.metadata.name.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.metadata.name.remoteWriteProxy.service" -}}
{{ template "sumologic.metadata.name.remoteWriteProxy" . }}
{{- end -}}

{{- define "sumologic.labels.metrics" -}}
sumologic.com/app: fluentd-metrics
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.labels.metrics.remoteWriteProxy" -}}
sumologic.com/app: metrics-remote-write-proxy
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.label.scrape" -}}
sumologic.com/scrape: "true"
{{- end -}}

{{- define "sumologic.labels.scrape.metrics" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.metrics" -}}
{{- template "sumologic.metadata.name.pvcCleaner" . }}-metrics
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.metrics" -}}
{{- template "sumologic.labels.app.pvcCleaner" . }}-metrics
{{- end -}}

{{/*
Definitions for metrics collector
*/}}

{{- define "sumologic.labels.component.metrics" -}}
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.labels.app.metrics.collector" -}}
sumologic.com/app: otelcol
{{- end -}}

{{- define "sumologic.labels.app.metrics.collector.pod" -}}
{{ template "sumologic.labels.app.metrics.collector" . }}
{{ template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.clusterrole" -}}
{{- template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.clusterrolebinding" -}}
{{- template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.serviceaccount" -}}
{{- template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.metrics.opentelemetrycollector" -}}
{{ template "sumologic.labels.app.metrics.collector" . }}
{{ template "sumologic.labels.component.metrics" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector" -}}
{{- template "sumologic.fullname" . }}-metrics
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.opentelemetrycollector" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.serviceaccount" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.clusterrole" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.clusterrolebinding.prometheus" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}-prometheus
{{- end -}}

{{- define "sumologic.metadata.name.metrics.collector.clusterrolebinding.metadata" -}}
{{ template "sumologic.metadata.name.metrics.collector" . }}-metadata
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.name" -}}
{{ template "sumologic.metadata.name.metrics.collector.opentelemetrycollector" . }}-targetallocator
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.serviceaccount" -}}
{{ template "sumologic.metadata.name.metrics.targetallocator.name" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.clusterrole" -}}
{{ template "sumologic.metadata.name.metrics.targetallocator.name" . }}
{{- end -}}

{{- define "sumologic.metadata.name.metrics.targetallocator.clusterrolebinding" -}}
{{ template "sumologic.metadata.name.metrics.targetallocator.name" . }}
{{- end -}}


{{/*
Generate metrics match configuration

Example usage (as one line):

{{ include "utils.metrics.match" (dict
  "Values" .
  "Tag" "prometheus.metrics.kubelet"
  "Endpoint" "SUMO_ENDPOINT_METRICS"
  "Storage" .Values.fluentd.buffer.filePaths.metrics.default
  "Id" sumologic.endpoint.metrics
)}}
*/}}
{{- define "utils.metrics.match" -}}
<match {{ .Tag }}>
  @type copy
  <store>
{{- if .Drop }}
    @type null
{{- else }}
    @type sumologic
    @id {{ .Id }}
    sumo_client {{ include "sumologic.sumo_client" .Context | quote }}
    endpoint "#{ENV['{{ include "terraform.sources.endpoint" .Endpoint}}']}"
{{- .Context.Values.fluentd.metrics.outputConf | nindent 2 }}
    <buffer>
      {{- if or .Context.Values.fluentd.persistence.enabled (eq .Context.Values.fluentd.buffer.type "file") }}
      @type file
      path {{ .Storage }}
      {{- else }}
      @type memory
      {{- end }}
      @include buffer.output.conf
    </buffer>
{{- end }}
  </store>
  {{- if .Context.Values.fluentd.monitoring.output }}
  {{ include "fluentd.prometheus-metrics.output" . | nindent 2 }}
  {{- end }}
</match>
{{ end -}}

{{/*
Generate fluentd prometheus filter configuration (input metrics)

Example:

{{ template "fluentd.prometheus-metrics.input" (dict "Tag" "kubernetes.**") }}
*/}}
{{- define "fluentd.prometheus-metrics.input" }}
<filter {{ .Tag }}>
  @type prometheus
  <metric>
    name fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</filter>
{{- end -}}

{{/*
Generate fluentd prometheus store configuration (output metrics)

Example:

{{ template "fluentd.prometheus-metrics.output" . }}
*/}}
{{- define "fluentd.prometheus-metrics.output" -}}
<store>
  @type prometheus
  <metric>
    name fluentd_output_status_num_records_total
    type counter
    desc The total number of outgoing records
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</store>
{{- end -}}
