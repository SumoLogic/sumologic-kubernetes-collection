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

{{- define "sumologic.labels.app.otelcolinstrumentation.hpa" -}}
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

{{- define "sumologic.labels.app.tracesgateway.hpa" -}}
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

{{- define "sumologic.metadata.name.otelcolinstrumentation.hpa" -}}
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

{{- define "sumologic.metadata.name.tracesgateway.hpa" -}}
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
{{ printf "%s.%s" ( include "sumologic.metadata.name.instrumentation.otelagent.service" . ) ( include "sumologic.namespace" .  ) }}
{{- end -}}

{{/*
Endpoint used by otelcol-instrumentation exporter.

Example Usage:
{{- $otelcolService := include "otelcolinstrumentation.exporter.endpoint" . }}

*/}}
{{- define "otelcolinstrumentation.exporter.endpoint" -}}
{{ $tracesGatewayEnabled := .Values.tracesGateway.enabled }}
{{- if (eq $tracesGatewayEnabled true) }}
{{- printf "%s.%s" ( include "sumologic.metadata.name.tracesgateway.service" . ) ( include "sumologic.namespace" .  ) }}
{{- else }}
{{- printf "%s.%s" ( include "sumologic.metadata.name.tracessampler.service" . ) ( include "sumologic.namespace" .  ) }}
{{- end }}
{{- end -}}

{{/*
Endpoint used by tracesgateway loadbalancing exporter.

Example Usage:
'{{ include "tracesgateway.exporter.loadbalancing.endpoint" . }}'
*/}}
{{- define "tracesgateway.exporter.loadbalancing.endpoint" -}}
{{- printf "%s.%s" ( include "sumologic.metadata.name.tracessampler.service-headless" . ) ( include "sumologic.namespace" .  ) }}
{{- end -}}

{{- define "opentelemetry-operator.controller.manager.metrics.service.url" -}}
http://{{ .Release.Name }}-opentelemetry-operator.{{ template "sumologic.namespace" . }}:8080/metrics
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

{{/*
Check if autoscaling for otelcol instrumentation is enabled.

Example Usage:
{{- if eq (include "otelcolInstrumentation.autoscaling.enabled" .) "true" }}

*/}}
{{- define "otelcolInstrumentation.autoscaling.enabled" -}}
{{- template "is.autoscaling.enabled" (dict "autoscalingEnabled" .Values.otelcolInstrumentation.autoscaling.enabled "Values" .Values) }}
{{- end -}}

{{- define "otelcolInstrumentation.statefulset.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.otelcolInstrumentation.statefulset.nodeSelector)}}
{{- end -}}

{{- define "otelcolInstrumentation.statefulset.tolerations" -}}
{{- if .Values.otelcolInstrumentation.statefulset.tolerations -}}
{{- toYaml .Values.otelcolInstrumentation.statefulset.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "otelcolInstrumentation.statefulset.affinity" -}}
{{- if .Values.otelcolInstrumentation.statefulset.affinity -}}
{{- toYaml .Values.otelcolInstrumentation.statefulset.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}

{{/*
Check if autoscaling for traces gateway is enabled.

Example Usage:
{{- if eq (include "tracesGateway.autoscaling.enabled" .) "true" }}

*/}}
{{- define "tracesGateway.autoscaling.enabled" -}}
{{- template "is.autoscaling.enabled" (dict "autoscalingEnabled" .Values.tracesGateway.autoscaling.enabled "Values" .Values) }}
{{- end -}}

{{- define "tracesGateway.deployment.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.tracesGateway.deployment.nodeSelector)}}
{{- end -}}

{{- define "tracesGateway.deployment.tolerations" -}}
{{- if .Values.tracesGateway.deployment.tolerations -}}
{{- toYaml .Values.tracesGateway.deployment.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "tracesSampler.deployment.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.tracesSampler.deployment.nodeSelector)}}
{{- end -}}

{{- define "tracesSampler.deployment.tolerations" -}}
{{- if .Values.tracesSampler.deployment.tolerations -}}
{{- toYaml .Values.tracesSampler.deployment.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "otelcolInstrumentation.collector.files.list" -}}
- /var/log/pods/{{ template "sumologic.namespace" . }}_{{ template "sumologic.metadata.name.otelcolinstrumentation" . }}*/*/*.log
{{- end -}}

{{- define "tracesGateway.collector.files.list" -}}
- /var/log/pods/{{ template "sumologic.namespace" . }}_{{ template "sumologic.metadata.name.tracesgateway" . }}*/*/*.log
{{- end -}}

{{- define "tracesSampler.collector.files.list" -}}
- /var/log/pods/{{ template "sumologic.namespace" . }}_{{ template "sumologic.metadata.name.tracessampler" . }}*/*/*.log
{{- end -}}
