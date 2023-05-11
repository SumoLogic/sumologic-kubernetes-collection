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

{{- define "sumologic.labels.events" -}}
{{- if eq .Values.sumologic.events.provider "fluentd" -}}
sumologic.com/app: fluentd-events
{{- else -}}
sumologic.com/app: otelcol-events
{{- end }}
sumologic.com/component: events
{{- end -}}

{{- define "sumologic.labels.scrape.events" -}}
{{ template "sumologic.label.scrape" . }}
{{ template "sumologic.labels.events" . }}
{{- end -}}

{{/*
Return the otelcol events image
*/}}
{{- define "sumologic.events.image" -}}
{{ template "utils.getOtelImage" (dict "overrideImage" .Values.otelevents.image "defaultImage" .Values.sumologic.otelcolImage) }}
{{- end -}}
