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
If dryRun=true, we use fixed value "fluentd".
*/}}
{{- define "sumologic.fullname" -}}
{{- if .Values.dryRun }}
{{- printf "fluentd" }}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}

{{/*
Create default fully qualified labels.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If dryRun=true, we use the Chart name "sumologic" and do not include labels specific to Helm.
*/}}
{{- define "sumologic.labels.app" -}}
{{- if .Values.dryRun }}
{{- template "sumologic.name" . }}
{{- else -}}
{{- template "sumologic.fullname" . }}
{{- end -}}
{{- end -}}

{{- define "sumologic.labels.common" -}}
{{- if .Values.dryRun -}}
{{- else -}}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
{{- end -}}
{{- end -}}
