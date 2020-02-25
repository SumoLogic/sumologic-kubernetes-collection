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
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Create default fully qualified labels.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sumologic.labels.app" -}}
{{- template "sumologic.fullname" . }}
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
Generate list of extensions/receivers/etc from dictionary:

Example input:
```
extensions:
  extension_a:
    enabled: true
  extension_b:
    enabled: false
```

Usage: include "otelcol.generate_list" extensions"

Expected output:
```
- extension_a
```
*/}}
{{- define "otelcol.generate_list" -}}
{{- $empty_list := true }}
{{- range $key, $val := . }}
  {{- if $val.enabled }}
    {{- if $empty_list }}
      {{- $empty_list = false }}
    {{- end }}
- {{ $key | quote }}
  {{- end }}
{{- end }}
{{- if $empty_list }} [] {{ end }}
{{- end -}}
