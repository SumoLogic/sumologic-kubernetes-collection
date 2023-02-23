{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "sumologic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sumologic.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}

{{/*
Create default fully qualified labels.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sumologic.labels.app" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.clusterrole" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.clusterrolebinding" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.labels.app.fluentd" -}}
{{- template "sumologic.fullname" . }}-fluentd
{{- end -}}

{{- define "sumologic.labels.app.logs" -}}
{{- if eq .Values.sumologic.logs.metadata.provider "fluentd" -}}
{{ template "sumologic.labels.app.fluentd" . }}-logs
{{- else if eq .Values.sumologic.logs.metadata.provider "otelcol" -}}
{{ template "sumologic.labels.app.otelcol" . }}-logs
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.configmap" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.serviceaccount" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.daemonset" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector.service" -}}
{{- template "sumologic.metadata.name.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector" -}}
{{- template "sumologic.fullname" . }}-otelcol-logs-collector
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.configmap" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.serviceaccount" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.daemonset" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.pod" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.collector.service" -}}
{{- template "sumologic.labels.app.logs.collector" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.pod" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.service" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.service-headless" -}}
{{- template "sumologic.labels.app.logs.service" . }}-headless
{{- end -}}

{{- define "sumologic.labels.app.logs.configmap" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.statefulset" -}}
{{- template "sumologic.labels.app.logs" . }}
{{- end -}}

{{- define "sumologic.labels.app.logs.hpa" -}}
{{- template "sumologic.labels.app.logs" . }}
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

{{- define "sumologic.labels.app.events" -}}
{{- if eq (include "events.fluentd.enabled" .) "true"  -}}
{{ template "sumologic.labels.app.fluentd" . }}-events
{{- else if eq (include "events.otelcol.enabled" .) "true" -}}
{{ template "sumologic.labels.app.otelcol" . }}-events
{{- end -}}
{{- end -}}

{{- define "sumologic.labels.app.events.pod" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.events.service" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.events.service-headless" -}}
{{- template "sumologic.labels.app.events.service" . }}-headless
{{- end -}}

{{- define "sumologic.labels.app.events.configmap" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.events.statefulset" -}}
{{- template "sumologic.labels.app.events" . }}
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator" -}}
{{- template "sumologic.fullname" . }}-ot-operator
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator.instrumentation" -}}
{{- template "sumologic.labels.app.opentelemetry.operator" . }}-instr
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator.instrumentation.configmap" -}}
{{- template "sumologic.labels.app.opentelemetry.operator.instrumentation" . }}-cm
{{- end -}}

{{- define "sumologic.labels.app.opentelemetry.operator.instrumentation.job" -}}
{{- template "sumologic.labels.app.opentelemetry.operator.instrumentation" . }}
{{- end -}}

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

{{- define "sumologic.labels.app.setup" -}}
{{- template "sumologic.labels.app" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.job" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.configmap" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.configmap-custom" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.role" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.rolebinding" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.roles.serviceaccount" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.setup.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-setup-scc
{{- end -}}

{{- define "sumologic.labels.app.setup.secret" -}}
{{- template "sumologic.labels.app.setup" . }}
{{- end -}}

{{- define "sumologic.labels.app.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-scc
{{- end -}}

{{- define "sumologic.labels.app.cleanup" -}}
{{- template "sumologic.labels.app" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.configmap" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.role" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.rolebinding" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.cleanup.roles.serviceaccount" -}}
{{- template "sumologic.labels.app.cleanup" . }}
{{- end -}}

{{- define "sumologic.labels.app.machineconfig.worker" -}}
{{- template "sumologic.fullname" . }}-worker-extensions
{{- end -}}

{{- define "sumologic.labels.machineconfig.worker" -}}
machineconfiguration.openshift.io/role: worker
{{- end -}}

{{- define "sumologic.labels.app.machineconfig.master" -}}
{{- template "sumologic.fullname" . }}-master-extensions
{{- end -}}

{{- define "sumologic.labels.machineconfig.master" -}}
machineconfiguration.openshift.io/role: master
{{- end -}}

{{/*
Generate cleanup job helm.sh annotations. It takes weight as parameter.

Example usage:

{{ include "sumologic.annotations.app.cleanup.helmsh" "1" }}

*/}}
{{- define "sumologic.annotations.app.cleanup.helmsh" -}}
helm.sh/hook: pre-delete
helm.sh/hook-weight: {{ printf "\"%s\"" . }}
helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
{{- end -}}

{{/*
Generate setup job helm.sh annotations. It takes weight as parameter.

Example usage:

{{ include "sumologic.annotations.app.setup.helmsh" "1" }}

*/}}
{{- define "sumologic.annotations.app.setup.helmsh" -}}
helm.sh/hook: pre-install,pre-upgrade
helm.sh/hook-weight: {{ printf "\"%s\"" . }}
helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
{{- end -}}

{{- define "sumologic.metadata.name.roles.clusterrole" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.roles.clusterrolebinding" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}
{{- end -}}

{{- define "sumologic.metadata.name.securitycontextconstraints" -}}
{{- template "sumologic.fullname" . }}-scc
{{- end -}}

{{- define "sumologic.metadata.name.fluentd" -}}
{{ template "sumologic.fullname" . }}-fluentd
{{- end -}}

{{- define "sumologic.metadata.name.logs" -}}
{{- if eq .Values.sumologic.logs.metadata.provider "fluentd" -}}
{{ template "sumologic.metadata.name.fluentd" . }}-logs
{{- else if eq .Values.sumologic.logs.metadata.provider "otelcol" -}}
{{ template "sumologic.metadata.name.otelcol" . }}-logs
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.logs.service" -}}
{{ template "sumologic.fullname" . }}-metadata-logs
{{- end -}}

{{- define "sumologic.metadata.name.logs.service-headless" -}}
{{ template "sumologic.metadata.name.logs" . }}-headless
{{- end -}}

{{- define "sumologic.metadata.name.logs.configmap" -}}
{{ template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.statefulset" -}}
{{ template "sumologic.metadata.name.logs" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.pdb" -}}
{{ template "sumologic.metadata.name.logs.statefulset" . }}-pdb
{{- end -}}

{{- define "sumologic.metadata.name.logs.hpa" -}}
{{- template "sumologic.metadata.name.logs" . }}
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

{{- define "sumologic.metadata.name.events" -}}
{{- if eq (include "events.fluentd.enabled" .) "true" -}}
{{ template "sumologic.metadata.name.fluentd" . }}-events
{{- else if eq (include "events.otelcol.enabled" .) "true" -}}
{{ template "sumologic.metadata.name.otelcol" . }}-events
{{- end -}}
{{- end -}}

{{- define "sumologic.metadata.name.events.service" -}}
{{ template "sumologic.metadata.name.events" . }}
{{- end -}}

{{- define "sumologic.metadata.name.events.service-headless" -}}
{{ template "sumologic.metadata.name.events.service" . }}-headless
{{- end -}}

{{- define "sumologic.metadata.name.events.configmap" -}}
{{ template "sumologic.metadata.name.events" . }}
{{- end -}}

{{- define "sumologic.metadata.name.events.statefulset" -}}
{{ template "sumologic.metadata.name.events" . }}
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator" -}}
{{ template "sumologic.fullname" . }}-ot-operator
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator.instrumentation" -}}
{{ template "sumologic.metadata.name.opentelemetry.operator" . }}-instr
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator.instrumentation.configmap" -}}
{{ template "sumologic.metadata.name.opentelemetry.operator.instrumentation" . }}-cm
{{- end -}}

{{- define "sumologic.metadata.name.opentelemetry.operator.instrumentation.job" -}}
{{ template "sumologic.metadata.name.opentelemetry.operator.instrumentation" . }}
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

{{- define "sumologic.metadata.name.setup" -}}
{{ template "sumologic.fullname" . }}-setup
{{- end -}}

{{- define "sumologic.metadata.name.setup.job" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.configmap-custom" -}}
{{ template "sumologic.metadata.name.setup" . }}-custom
{{- end -}}

{{- define "sumologic.metadata.name.setup.configmap" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.role" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.rolebinding" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.roles.serviceaccount" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.setup.securitycontextconstraints" -}}
{{- template "sumologic.metadata.name.setup" . }}-scc
{{- end -}}

{{- define "sumologic.metadata.name.setup.secret" -}}
{{ template "sumologic.metadata.name.setup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup" -}}
{{ template "sumologic.fullname" . }}-cleanup
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.configmap" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.role" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.rolebinding" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.cleanup.roles.serviceaccount" -}}
{{ template "sumologic.metadata.name.cleanup" . }}
{{- end -}}

{{- define "sumologic.metadata.name.logs.collector" -}}
{{- template "sumologic.fullname" . }}-otelcol-logs-collector
{{- end -}}

{{- define "sumologic.labels.logs" -}}
sumologic.com/app: fluentd-logs
sumologic.com/component: logs
{{- end -}}

{{- define "sumologic.labels.metrics" -}}
sumologic.com/app: fluentd-metrics
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.labels.metrics.remoteWriteProxy" -}}
sumologic.com/app: metrics-remote-write-proxy
sumologic.com/component: metrics
{{- end -}}

{{- define "sumologic.labels.events" -}}
{{- if eq .Values.sumologic.events.provider "fluentd" -}}
sumologic.com/app: fluentd-events
{{- else -}}
sumologic.com/app: otelcol-events
{{- end }}
sumologic.com/component: events
{{- end -}}

{{- define "sumologic.labels.instrumentation.component" -}}
sumologic.com/component: instrumentation
{{- end -}}

{{- define "sumologic.labels.logs.collector" -}}
sumologic.com/app: otelcol-logs-collector
sumologic.com/component: logs
{{- end -}}

{{- define "sumologic.label.scrape" -}}
sumologic.com/scrape: "true"
{{- end -}}

{{- define "sumologic.labels.scrape.logs" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.logs" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.metrics" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.metrics" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.events" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.events" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.instrumentation" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.instrumentation.component" . }}
{{- end -}}

{{- define "sumologic.labels.scrape.logs.collector" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.logs.collector" . }}
{{- end -}}

{{- define "sumologic.metadata.name.priorityclass" -}}
{{ template "sumologic.fullname" . }}-priorityclass
{{- end -}}

{{- define "sumologic.metadata.name.instrumentation.deprecated.otelcol.service" -}}
{{ template "sumologic.fullname" . }}-otelcol
{{- end -}}

{{- define "sumologic.metadata.name.instrumentation.otelagent.service" -}}
{{ template "sumologic.fullname" . }}-otelagent
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner" -}}
{{- template "sumologic.fullname" . }}-pvc-cleaner
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.logs" -}}
{{- template "sumologic.metadata.name.pvcCleaner" . }}-logs
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.metrics" -}}
{{- template "sumologic.metadata.name.pvcCleaner" . }}-metrics
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner" -}}
pvc-cleaner
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.logs" -}}
{{- template "sumologic.labels.app.pvcCleaner" . }}-logs
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.metrics" -}}
{{- template "sumologic.labels.app.pvcCleaner" . }}-metrics
{{- end -}}

{{- define "sumologic.metadata.name.pvcCleaner.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}-pvc-cleaner
{{- end -}}

{{- define "sumologic.labels.app.pvcCleaner.roles.serviceaccount" -}}
{{- template "sumologic.fullname" . }}-pvc-cleaner
{{- end -}}


{{/*
Create endpoint based on OTC Tracing deployment type
*/}}
{{- define "sumologic.opentelemetry.operator.instrumentation.collector.endpoint" -}}
{{ printf "%s.%s" ( include "sumologic.metadata.name.instrumentation.otelagent.service" . ) .Release.Namespace }}
{{- end -}}

{{/*
Create common labels used throughout the chart.
If dryRun=true, we do not create any chart labels.
*/}}
{{- define "sumologic.labels.common" -}}
{{- if .Values.dryRun -}}
{{- else -}}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: "{{ .Release.Name }}"
heritage: "{{ .Release.Service }}"
{{- end -}}
{{- end -}}

{{/*
Returns sumologic version string
*/}}
{{- define "sumologic.sumo_client" -}}
k8s_{{ .Chart.Version }}
{{- end -}}

{{/*
Returns clusterName with spaces replaced with dashes
*/}}
{{- define "sumologic.clusterNameReplaceSpaceWithDash" -}}
{{ .Values.sumologic.clusterName | replace " " "-"}}
{{- end -}}

{{/*
Get configuration value, otherwise returns default

Example usage:

{{ include "utils.get_default" (dict "Values" .Values "Keys" (list "key1" "key2") "Default" "default_value") | quote }}

It returns `.Value.key1.key2` if it exists otherwise `default_value`

*/}}
{{- define "utils.get_default" -}}
{{- $dict := .Values -}}
{{- $keys := .Keys -}}
{{- $default := .Default -}}
{{- $success := true }}
{{- range $keys -}}
  {{- if (and $success (hasKey $dict .)) }}
    {{- $dict = index $dict . }}
  {{- else }}
    {{- $success = false }}
  {{- end }}
{{- end }}
{{- if $success }}
  {{- $dict }}
{{- else }}
  {{- $default }}
{{- end }}
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

{{/*
Returns the name of Kubernetes secret.

Example usage:

{{ include "terraform.secret.name" }}

*/}}
{{- define "terraform.secret.name" -}}
{{ printf "%s" "sumologic" }}
{{- end -}}

{{/*
Returns the name of Kubernetes secret prefixed with release namespace.

Example usage:

{{ include "terraform.secret.fullname" }}

*/}}
{{- define "terraform.secret.fullname" -}}
{{ .Release.Namespace }}/{{ template "terraform.secret.name" . }}
{{- end -}}

{{/*
Convert source name to Terraform metric name:
 * converts all `-` to `_`
 * adds `_$type_source` suffix

Example usage:

{{ include "terraform.sources.name" $source }}

*/}}
{{- define "terraform.sources.name" -}}
{{ printf "%s_%s_source" (replace "-" "_" .Name) .Type }}
{{- end -}}

{{/*
Generate endpoint variable string for given string

Example usage:

{{ include "terraform.sources.endpoint" "logs" }}

*/}}
{{- define "terraform.sources.endpoint" -}}
SUMO_ENDPOINT_{{ replace "-" "_" . | upper }}
{{- end -}}

{{/*
Generate endpoint variable string for given string

Example usage:

{{ include "terraform.sources.endpoint" "logs" }}

*/}}
{{- define "terraform.sources.endpoint_name" -}}
{{ printf "endpoint-%s" . }}
{{- end -}}

{{/*
Generate line for local Terraform section
 * `terraform.sources.local = value`

Example usage:

{{ include "terraform.sources.local" $source }}

*/}}
{{- define "terraform.sources.local" -}}
{{ printf "%-43s = \"%s\"" .Name .Value }}
{{- end -}}

{{/*
Generate line for data Terraform section

Example usage:

{{ include "terraform.sources.data" (dict "Endpoint" "enpoint-default-metrics" "Name" "default") }}

*/}}
{{- define "terraform.sources.data" -}}
{{ printf "%-41s = sumologic_http_source.%s.url" .Endpoint .Name }}
{{- end -}}

{{/*
Returns the collector name.

Example usage:

{{ include "terraform.collector.name" . }}

*/}}
{{- define "terraform.collector.name" -}}
{{- if .Values.sumologic.collectorName }}{{ .Values.sumologic.collectorName }}{{- else}}{{ .Values.sumologic.clusterName }}{{- end}}
{{- end -}}

{{/*
Generate resource sections

Example usage:

{{ include "terraform.sources.resource" (dict "Source" $source "Context" $ctx) }}

*/}}
{{- define "terraform.sources.resource" -}}
{{- $source := .Source -}}
{{- $ctx := .Context -}}
resource "sumologic_http_source" "{{ .Name }}" {
    name         = local.{{ .Name }}
    collector_id = sumologic_collector.collector.id
    {{- if $source.properties }}
    {{- range $fkey, $fvalue := $source.properties }}
    {{- include "terraform.generate-object" (dict "Name" $fkey "Value" $fvalue "KeyLength" (include "terraform.max-key-length" $source.properties) "Indent" 2) -}}
    {{- end -}}
    {{- end }}
}
{{- end -}}

{{- define "terraform.max-key-length" -}}
{{- $max := 0 -}}
{{- range $key, $value := . -}}
{{- if gt (len $key) $max -}}
{{- $max = (len $key) -}}
{{- end -}}
{{- end -}}
{{ $max }}
{{- end -}}

{{/*
Generate key for Terraform object. Default behaviour is to print:

{{ name }} = {{ value }}

If this is key for list, prints only value.

This template takes care about indentation using Indent key

Example usage:

{{- include "terraform.generate-object" (dict "Name" "my_key" "Value" "my_value" "Indent" 8 "List" true) }}
*/}}
{{- define "terraform.generate-key" -}}
{{- $indent := int .Indent -}}
{{- $name := .Name -}}
{{- $keyLength := int .KeyLength -}}
{{- $format := printf "%%-%ss" (toString $keyLength) -}}
{{- $value := .Value -}}
{{- if and ( eq (kindOf $value) "string") (not .SkipEscaping) -}}
{{- $value = printf "\"%s\"" $value -}}
{{- end -}}
{{- if .SkipPadding -}}
{{- $format = "%s" -}}
{{- end -}}
{{ indent (int $indent) "" }}{{ if not .SkipName }}{{ printf $format (toString $name) }} {{ if not .SkipEqual }}= {{ end }}{{ end }}{{ (toString $value) }}{{ if .AddComma }},{{ end }}
{{- end -}}

{{/*
Generates Terraform object for primitives, slices and maps

Example usage:

{{- include "terraform.generate-object" (dict "Name" $name "Value" $value "Indent" 12 "List" true) }}

where:
  - Value can be slice, map or primitive type (int, string, etc)
  - Name is string
  - Indent should be convertable to int (0 by default)
  - List - information if the Value is element of the list, false by default
*/}}
{{- define "terraform.generate-object" -}}
{{- $name := .Name -}}
{{- $value := .Value -}}
{{- $keyLength := .KeyLength -}}
{{- $indent := int .Indent -}}
{{- $indent = add $indent 2 -}}
{{- $process := true -}}
{{- if eq (kindOf $value) "slice" }}
{{- range $sname, $svalue := $value }}
{{- if eq (kindOf $svalue) "map" }}
{{- $process = false }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" "{" "SkipPadding" true "SkipEqual" true "SkipEscaping" true "KeyLength" $keyLength "Indent" $indent) }}
{{- range $tname, $tvalue := $svalue }}
{{- include "terraform.generate-object" (dict "Name" $tname "Value" $tvalue "Indent" $indent "KeyLength" (include "terraform.max-key-length" $svalue)) }}
{{- end }}
{{ printf "}" | indent (int $indent) }}
{{- end }}
{{- end }}
{{- if $process }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" "[" "SkipPadding" true "SkipEscaping" true "KeyLength" $keyLength "Indent" $indent) }}
{{- range $sname, $svalue := $value }}
{{ include "terraform.generate-key" (dict "Name" $sname "Value" $svalue "SkipName" true "AddComma" true "Indent" (add $indent 2)) }}
{{- end }}
{{ printf "]" | indent (int $indent) }}
{{- end }}
{{- else if eq (kindOf $value) "map" }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" "{" "SkipPadding" true "SkipEscaping" true "KeyLength" $keyLength "Indent" $indent) }}
{{- range $sname, $svalue := $value }}
{{- include "terraform.generate-object" (dict "Name" $sname "Value" $svalue "KeyLength" (include "terraform.max-key-length" $value) "Indent" $indent) }}
{{- end }}
{{ printf "}" | indent (int $indent) }}
{{- else }}
{{ include "terraform.generate-key" (dict "Name" $name "Value" $value "KeyLength" $keyLength "Indent" $indent) }}
{{- end -}}
{{- end -}}

{{/*
get configuration variable name for sources confg map

Example usage:

{{ include "terraform.sources.config-map-variable" (dict "Context" .Values "Name" $name "Endpoint" $endpoint) }}

*/}}
{{- define "terraform.sources.config-map-variable" -}}
{{- $name := .Name -}}
{{- $ctx := .Context -}}
{{- $type := .Type -}}
{{- $endpoint := .Endpoint -}}
{{- if not $endpoint -}}
{{- $source := (index $ctx.sumologic.collector.sources $type "default") -}}
{{- if (index $ctx.sumologic.collector.sources $type .Name "config-name") -}}
{{- $endpoint = index $ctx.sumologic.collector.sources $type .Name "config-name" -}}
{{- else -}}
{{- $endpoint = printf "endpoint-%s" (include "terraform.sources.name" (dict "Name" $name "Type" $type)) -}}
{{- end -}}
{{- end -}}
{{ $endpoint }}
{{- end -}}

{{/*
Add or skip quotation denending on the value

Examples:
  - "${test}" will be printed as `test`
  - "test" will be printed as `"test"`

Example Usage:
{{ include "terraform.sources.config-map-variable" "${file(\"/var/test\")}" }}

*/}}
{{- define "terraform.print_value" -}}
{{- if and (kindIs "string" .) -}}
{{- if (regexMatch "^\\$\\{[^\\$]*\\}$" .) -}}
{{ regexReplaceAll "^\\$\\{(.*)\\}$" . "${1}" }}
{{- else -}}
{{ printf "\"%s\"" . }}
{{- end -}}
{{- else -}}
{{ printf "\"%s\"" (toString .) }}
{{- end -}}
{{- end -}}

{{/*
Check if component (source/events/logs/traces etc.) is enabled or not

Example Usage:
{{- if eq (include "terraform.sources.component_enabled" (dict "Values" .Values "Type" "metrics")) "true" }}

*/}}
{{- define "terraform.sources.component_enabled" -}}
{{- $type := .Type -}}
{{- $ctx := .Values -}}
{{- $value := true -}}
{{- if hasKey $ctx.sumologic $type -}}
{{- if not (index $ctx.sumologic $type "enabled") -}}
{{- $value = false -}}
{{- end -}}
{{- end -}}
{{- if eq $type "events" -}}
{{ $value = include "events.enabled" . }}
{{- end -}}
{{ $value }}
{{- end -}}

{{/*
Check if particular source is enabled or not

Example Usage:
{{- if eq (include "terraform.sources.to_create" (dict "Context" .Values "Type" "metrics" .Name "default" )) "true" }}

*/}}
{{- define "terraform.sources.to_create" -}}
{{- $type := .Type -}}
{{- $ctx := .Context -}}
{{- $name := .Name -}}
{{- $value := true -}}
{{- if and (hasKey $ctx.sumologic.collector.sources $type) (hasKey (index $ctx.sumologic.collector.sources $type) $name) (hasKey (index $ctx.sumologic.collector.sources $type $name) "create") -}}
{{- if not (index $ctx.sumologic.collector.sources $type $name "create") -}}
{{- $value = false -}}
{{- end -}}
{{- end -}}
{{ $value }}
{{- end -}}

{{/*
Generate fluentd envs for given source type:

Example:

{{ include "kubernetes.sources.envs" (dict "Context" .Values "Type" "metrics")}}
*/}}
{{- define "kubernetes.sources.envs" -}}
{{- $ctx := .Context -}}
{{- $type := .Type -}}
{{- range $name, $source := (index .Context.sumologic.collector.sources $type) -}}
{{- include "kubernetes.sources.env" (dict "Context" $ctx "Type" $type  "Name" $name ) | nindent 8 -}}
{{- end }}
{{- end -}}

{{/*
Generate fluentd envs for given source type:

Example:

{{ include "kubernetes.sources.env" (dict "Context" .Values "Type" "metrics" "Name" $name ) }}
*/}}
{{- define "kubernetes.sources.env" -}}
{{- $ctx := .Context -}}
{{- $type := .Type -}}
{{- $name := .Name -}}
- name: {{ template "terraform.sources.endpoint" (include "terraform.sources.name" (dict "Name" $name "Type" $type)) }}
  valueFrom:
    secretKeyRef:
      name: sumologic
      key: {{ template "terraform.sources.config-map-variable" (dict "Type" $type "Context" $ctx "Name" $name) }}
{{- end -}}


{{/*
Generate a space separated list of quoted values:

Example:

{{ include "helm-toolkit.utils.joinListWithSpaces" .Values.sumologic.logs.fields }}
*/}}
{{- define "helm-toolkit.utils.joinListWithSpaces" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}
{{- if not $local.first }} {{ end -}}
{{- $v | quote -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}


{{/*
Returns kubernetes minor version as integer (without additional chars like +)

Example:

{{ include "kubernetes.minor" . }}
*/}}
{{- define "kubernetes.minor" -}}
{{- print (regexFind "^\\d+" .Capabilities.KubeVersion.Minor) -}}
{{- end -}}

{{- define "fluentd.metadata.annotations_match.quotes" -}}
{{- $matches_with_quotes := list -}}
{{- range $match := .Values.fluentd.metadata.annotation_match  }}
{{- $match_with_quotes := printf "\"%s\"" $match }}
{{- $matches_with_quotes = append $matches_with_quotes $match_with_quotes }}
{{- end }}
{{- $matches_with_quotes_with_commas := join "," $matches_with_quotes }}
{{- $annotations_match := list $matches_with_quotes_with_commas }}
{{- print $annotations_match }}
{{- end -}}

{{/*
Returns list of namespaces to exclude

Example:

{{ include "logs.excludeNamespaces" . }}
*/}}
{{- define "logs.excludeNamespaces" -}}
{{- $excludeNamespaceRegex := .Values.sumologic.logs.container.excludeNamespaceRegex | quote -}}
{{- if eq .Values.sumologic.collectionMonitoring false -}}
  {{- if .Values.sumologic.logs.container.excludeNamespaceRegex -}}
  {{- $excludeNamespaceRegex = printf "%s|%s" .Release.Namespace .Values.sumologic.logs.container.excludeNamespaceRegex | quote -}}
  {{- else -}}
  {{- $excludeNamespaceRegex = printf "%s" .Release.Namespace | quote -}}
  {{- end -}}
{{- end -}}
{{ print $excludeNamespaceRegex }}
{{- end -}}


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
Check if remote write proxy is enabled.
Example Usage:
{{- if eq (include "metrics.remoteWriteProxy.enabled" .) "true" }}

*/}}
{{- define "metrics.remoteWriteProxy.enabled" -}}
{{ and (eq (include "metrics.enabled" .) "true") (eq .Values.sumologic.metrics.remoteWriteProxy.enabled true) }}
{{- end -}}


{{/*
Check if any logs metadata provider is enabled

Example Usage:
{{- if eq (include "logs.enabled" .) "true" }}

*/}}
{{- define "logs.enabled" -}}
{{- $enabled := false -}}
{{- if eq (include "logs.otelcol.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{- if eq (include "logs.fluentd.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{ $enabled }}
{{- end -}}


{{/*
Check if otelcol logs metadata provider is enabled

Example Usage:
{{- if eq (include "logs.otelcol.enabled" .) "true" }}

*/}}
{{- define "logs.otelcol.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.logs.enabled true -}}
{{- if and (eq .Values.sumologic.logs.metadata.provider "otelcol") (eq .Values.metadata.logs.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Check if fluentd logs metadata provider is enabled

Example Usage:
{{- if eq (include "logs.fluentd.enabled" .) "true" }}

*/}}
{{- define "logs.fluentd.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.logs.enabled true -}}
{{- if and (eq .Values.sumologic.logs.metadata.provider "fluentd") (eq .Values.fluentd.logs.enabled true) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Check if otelcol logs collector is enabled.
It's enabled if both logs in general and the collector specifically are enabled.
If both the collector and Fluent-Bit are enabled, we error.

Example Usage:
{{- if eq (include "logs.collector.otelcol.enabled" .) "true" }}

*/}}
{{- define "logs.collector.otelcol.enabled" -}}
{{- $enabled := and (eq (include "logs.enabled" .) "true") (eq .Values.sumologic.logs.collector.otelcol.enabled true) -}}
{{- $fluentBitEnabled := index .Values "fluent-bit" "enabled" -}}
{{- if kindIs "invalid" $fluentBitEnabled -}}
{{- $fluentBitEnabled = true -}}
{{- end -}}
{{- $sideBySideAllowed := .Values.sumologic.logs.collector.allowSideBySide -}}
{{- if and $enabled $fluentBitEnabled (not $sideBySideAllowed) -}}
{{- fail "Fluent-Bit and Otel log collector can't be enabled at the same time. Set either `fluent-bit.enabled` or `sumologic.logs.collector.otelcol.enabled` to false" -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Check if Fluent-Bit logs collector is enabled.
It's enabled if logs in general are enabled and fluent-bit.enabled is set to true.

Example Usage:
{{- if eq (include "logs.collector.fluentbit.enabled" .) "true" }}

*/}}
{{- define "logs.collector.fluentbit.enabled" -}}
{{- $fluentBitEnabled := index .Values "fluent-bit" "enabled" -}}
{{- if kindIs "invalid" $fluentBitEnabled -}}
{{- $fluentBitEnabled = true -}}
{{- end -}}
{{- $enabled := and (eq (include "logs.enabled" .) "true") $fluentBitEnabled -}}
{{- $otelLogCollectorEnabled := .Values.sumologic.logs.collector.otelcol.enabled -}}
{{- $sideBySideAllowed := .Values.sumologic.logs.collector.allowSideBySide -}}
{{- if and $enabled $otelLogCollectorEnabled (not $sideBySideAllowed) -}}
{{- fail "Fluent-Bit and Otel log collector can't be enabled at the same time. Set either `fluent-bit.enabled` or `sumologic.logs.collector.otelcol.enabled` to false" -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Check if any events provider is enabled
Example Usage:
{{- if eq (include "events.enabled" .) "true" }}

*/}}
{{- define "events.enabled" -}}
{{- $enabled := false -}}
{{- if eq (include "events.otelcol.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{- if eq (include "events.fluentd.enabled" .) "true" }}
{{- $enabled = true -}}
{{- end -}}
{{ $enabled }}
{{- end -}}


{{/*
Check if otelcol events provider is enabled
Example Usage:
{{- if eq (include "events.otelcol.enabled" .) "true" }}

*/}}
{{- define "events.otelcol.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.events.provider "otelcol" -}}
{{- $enabled = true -}}
{{- end -}}
{{- if hasKey .Values.sumologic.events "enabled" -}}
{{- if eq .Values.sumologic.events.enabled false -}}
{{- $enabled = false -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}


{{/*
Check if fluentd events provider is enabled
Example Usage:
{{- if eq (include "events.fluentd.enabled" .) "true" }}

*/}}
{{- define "events.fluentd.enabled" -}}
{{- $enabled := false -}}
{{- if eq .Values.sumologic.events.provider "fluentd" -}}
{{- $enabled = true -}}
{{- end -}}
{{- if hasKey .Values.sumologic.events "enabled" -}}
{{- if eq .Values.sumologic.events.enabled false -}}
{{- $enabled = false -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{/*
Add service labels

Example Usage:
{{- if eq (include "service.labels" dict("Provider" "fluentd" "Values" .Values)) "true" }}

*/}}
{{- define "service.labels" -}}
{{- if (get (get .Values .Provider) "serviceLabels") }}
{{ toYaml (get (get .Values .Provider) "serviceLabels") }}
{{- end }}
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
Environment variables used to configure the HTTP proxy for programs using
Go's net/http. See: https://pkg.go.dev/net/http#RoundTripper

Example Usage:
'{{ include "proxy-env-variables" . }}'
*/}}
{{- define "proxy-env-variables" -}}
{{- if .Values.sumologic.httpProxy -}}
- name: HTTP_PROXY
  value: {{ .Values.sumologic.httpProxy }}
{{- end -}}
{{- if .Values.sumologic.httpsProxy -}}
- name: HTTPS_PROXY
  value: {{ .Values.sumologic.httpsProxy }}
{{- end -}}
{{- if .Values.sumologic.noProxy -}}
- name: NO_PROXY
  value: {{ .Values.sumologic.noProxy }}
{{- end -}}
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
Return the log format for the Sumologic exporter for container logs.

'{{ include "logs.otelcol.container.exporter.format" . }}'
*/}}
{{- define "logs.otelcol.container.exporter.format" -}}
{{- $jsonFormats := list "json" "fields" "json_merge" -}}
{{- if has .Values.sumologic.logs.container.format $jsonFormats -}}
{{- "json" -}}
{{- else if eq .Values.sumologic.logs.container.format "text" -}}
{{- "text" -}}
{{- else -}}
{{- fail "`sumologic.logs.container.format` can only be `json`, `text`, `json_merge` or `fields`" -}}
{{- end -}}
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
