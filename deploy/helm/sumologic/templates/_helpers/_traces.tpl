{{- define "sumologic.labels.app.otelcol" -}}
{{- template "sumologic.fullname" . }}-otelcol
{{- end -}}

{{- define "sumologic.labels.app.tracessampler" -}}
{{- template "sumologic.fullname" . }}-traces-sampler
{{- end -}}

{{- define "sumologic.labels.app.tracessampler.pod" -}}
{{- template "sumologic.labels.app.tracessampler" . }}
{{- end -}}

{{- define "sumologic.labels.app.tracessampler.service" -}}
{{- template "sumologic.labels.app.tracessampler" . }}
{{- end -}}

{{- define "sumologic.labels.app.tracessampler.service-headless" -}}
{{- template "sumologic.labels.app.tracessampler.service" . }}-headless
{{- end -}}

{{- define "sumologic.labels.app.tracessampler.service-metrics" -}}
{{- template "sumologic.labels.app.tracessampler.service" . }}-instr-metrics
{{- end -}}

{{- define "sumologic.labels.app.tracessampler.configmap" -}}
{{- template "sumologic.labels.app.tracessampler" . }}
{{- end -}}

{{- define "sumologic.labels.app.tracessampler.deployment" -}}
{{- template "sumologic.labels.app.tracessampler" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcolinstrumentation" -}}
{{- template "sumologic.fullname" . }}-otelcol-instrumentation
{{- end -}}

{{- define "sumologic.labels.app.otelcolinstrumentation.pod" -}}
{{- template "sumologic.labels.app.otelcolinstrumentation" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcolinstrumentation.service" -}}
{{- template "sumologic.labels.app.otelcolinstrumentation" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcolinstrumentation.configmap" -}}
{{- template "sumologic.labels.app.otelcolinstrumentation" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcolinstrumentation.statefulset" -}}
{{- template "sumologic.labels.app.otelcolinstrumentation" . }}
{{- end -}}

{{- define "sumologic.labels.app.otelcolinstrumentation.component" -}}
{{- template "sumologic.labels.app.otelcolinstrumentation" . }}-component
{{- end -}}

{{- define "sumologic.labels.app.tracesgateway" -}}
{{- template "sumologic.fullname" . }}-traces-gateway
{{- end -}}

{{- define "sumologic.labels.app.tracesgateway.pod" -}}
{{- template "sumologic.labels.app.tracesgateway" . }}
{{- end -}}

{{- define "sumologic.labels.app.tracesgateway.service" -}}
{{- template "sumologic.labels.app.tracesgateway" . }}
{{- end -}}

{{- define "sumologic.labels.app.tracesgateway.configmap" -}}
{{- template "sumologic.labels.app.tracesgateway" . }}
{{- end -}}

{{- define "sumologic.labels.app.tracesgateway.deployment" -}}
{{- template "sumologic.labels.app.tracesgateway" . }}
{{- end -}}

{{- define "sumologic.labels.app.tracesgateway.component" -}}
{{- template "sumologic.labels.app.tracesgateway" . }}-component
{{- end -}}

{{- define "sumologic.metadata.name.otelcol" -}}
{{ template "sumologic.fullname" . }}-otelcol
{{- end -}}

{{- define "sumologic.metadata.name.tracessampler" -}}
{{ template "sumologic.fullname" . }}-traces-sampler
{{- end -}}

{{- define "sumologic.metadata.name.tracessampler.service" -}}
{{ template "sumologic.metadata.name.tracessampler" . }}
{{- end -}}

{{- define "sumologic.metadata.name.tracessampler.service-headless" -}}
{{ template "sumologic.metadata.name.tracessampler.service" . }}-headless
{{- end -}}

{{- define "sumologic.metadata.name.tracessampler.configmap" -}}
{{ template "sumologic.metadata.name.tracessampler" . }}
{{- end -}}

{{- define "sumologic.metadata.name.tracessampler.deployment" -}}
{{ template "sumologic.metadata.name.tracessampler" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelcolinstrumentation" -}}
{{ template "sumologic.fullname" . }}-otelcol-instrumentation
{{- end -}}

{{- define "sumologic.metadata.name.otelcolinstrumentation.service" -}}
{{ template "sumologic.metadata.name.otelcolinstrumentation" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelcolinstrumentation.configmap" -}}
{{ template "sumologic.metadata.name.otelcolinstrumentation" . }}
{{- end -}}

{{- define "sumologic.metadata.name.otelcolinstrumentation.statefulset" -}}
{{ template "sumologic.metadata.name.otelcolinstrumentation" . }}
{{- end -}}

{{- define "sumologic.metadata.name.tracesgateway" -}}
{{ template "sumologic.fullname" . }}-traces-gateway
{{- end -}}

{{- define "sumologic.metadata.name.tracesgateway.service" -}}
{{ template "sumologic.metadata.name.tracesgateway" . }}
{{- end -}}

{{- define "sumologic.metadata.name.tracesgateway.configmap" -}}
{{ template "sumologic.metadata.name.tracesgateway" . }}
{{- end -}}

{{- define "sumologic.metadata.name.tracesgateway.deployment" -}}
{{ template "sumologic.metadata.name.tracesgateway" . }}
{{- end -}}

{{- define "sumologic.labels.instrumentation.component" -}}
sumologic.com/component: instrumentation
{{- end -}}

{{- define "sumologic.labels.scrape.instrumentation" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.instrumentation.component" . }}
{{- end -}}

{{- define "sumologic.metadata.name.instrumentation.deprecated.otelcol.service" -}}
{{ template "sumologic.fullname" . }}-otelcol
{{- end -}}

{{- define "sumologic.metadata.name.instrumentation.otelagent.service" -}}
{{ template "sumologic.fullname" . }}-otelagent
{{- end -}}

{{/*
Return the otelcol agent image
*/}}
{{- define "sumologic.instrumentation.otelagent.image" -}}
{{ template "utils.getOtelImage" (dict "overrideImage" .Values.otelcolInstrumentation.statefulset.image "defaultImage" .Values.sumologic.otelcolImage) }}
{{- end -}}

{{/*
Return the otelcol trace sampler image
*/}}
{{- define "sumologic.tracessampler.image" -}}
{{ template "utils.getOtelImage" (dict "overrideImage" .Values.tracesSampler.deployment.image "defaultImage" .Values.sumologic.otelcolImage) }}
{{- end -}}

{{/*
Return the otelcol gateway image
*/}}
{{- define "sumologic.tracesgateway.image" -}}
{{ template "utils.getOtelImage" (dict "overrideImage" .Values.tracesGateway.deployment.image "defaultImage" .Values.sumologic.otelcolImage) }}
{{- end -}}

{{/*
Create endpoint based on OTC Tracing deployment type
*/}}
{{- define "sumologic.opentelemetry.operator.instrumentation.collector.endpoint" -}}
{{ printf "%s.%s" ( include "sumologic.metadata.name.instrumentation.otelagent.service" . ) .Release.Namespace }}
{{- end -}}

{{/*
Endpoint used by otelcol-instrumentation exporter.

Example Usage:
{{- $otelcolService := include "otelcolinstrumentation.exporter.endpoint" . }}

*/}}
{{- define "otelcolinstrumentation.exporter.endpoint" -}}
{{ $tracesGatewayEnabled := .Values.tracesGateway.enabled }}
{{- if (eq $tracesGatewayEnabled true) }}
{{- printf "%s.%s" ( include "sumologic.metadata.name.tracesgateway.service" . ) .Release.Namespace }}
{{- else }}
{{- printf "%s.%s" ( include "sumologic.metadata.name.tracessampler.service" . ) .Release.Namespace }}
{{- end }}
{{- end -}}

{{/*
Endpoint used by tracesgateway loadbalancing exporter.

Example Usage:
'{{ include "tracesgateway.exporter.loadbalancing.endpoint" . }}'
*/}}
{{- define "tracesgateway.exporter.loadbalancing.endpoint" -}}
{{- printf "%s.%s" ( include "sumologic.metadata.name.tracessampler.service-headless" . ) .Release.Namespace }}
{{- end -}}

{{- define "opentelemetry-operator.controller.manager.metrics.service.url" -}}
http://{{ .Release.Name }}-opentelemetry-operator.{{ .Release.Namespace }}:8080/metrics
{{- end -}}

{{/*
Return otlp or none for Instrumentation resource exporters configuration.

'{{ include "instrumentation.resource.exporter" (dict "enabled" .Values...) }}'
*/}}
{{- define "instrumentation.resource.exporter" }}
{{- $enabled := .enabled -}}
{{- if $enabled -}}
{{- "otlp" -}}
{{- else -}}
{{- "none" -}}
{{- end -}}
{{- end -}}