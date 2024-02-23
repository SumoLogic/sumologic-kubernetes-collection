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
{{ $enabled }}
{{- end -}}


{{/*
Check if otelcol events provider is enabled
Example Usage:
{{- if eq (include "events.otelcol.enabled" .) "true" }}

*/}}
{{- define "events.otelcol.enabled" -}}
{{- $enabled := true -}}
{{- if hasKey .Values.sumologic.events "enabled" -}}
{{- if eq .Values.sumologic.events.enabled false -}}
{{- $enabled = false -}}
{{- end -}}
{{- end -}}
{{ $enabled }}
{{- end -}}

{{- define "sumologic.labels.app.events" -}}
{{ template "sumologic.labels.app.otelcol" . }}-events
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
{{ template "sumologic.metadata.name.otelcol" . }}-events
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
sumologic.com/app: otelcol-events
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

{{/*
Return the events otel exporter endpoint
*/}}
{{- define "sumologic.events.exporter.endpoint" -}}
{{- if eq .Values.sumologic.events.sourceType "http" -}}
${SUMO_ENDPOINT_DEFAULT_EVENTS_SOURCE}
{{- else if eq .Values.sumologic.events.sourceType "otlp" -}}
${SUMO_ENDPOINT_DEFAULT_OTLP_EVENTS_SOURCE}
{{- else -}}
{{- fail "`sumologic.events.sourceType` can only be `http` or `otlp`" -}}
{{- end -}}
{{- end -}}

{{/*
Return the events otel exporter format
*/}}
{{- define "sumologic.events.exporter.format" -}}
{{- if eq .Values.sumologic.events.sourceType "http" -}}
json
{{- else if eq .Values.sumologic.events.sourceType "otlp" -}}
otlp
{{- else -}}
{{- fail "`sumologic.events.sourceType` can only be `http` or `otlp`" -}}
{{- end -}}
{{- end -}}

{{- define "events.collector.files.list" -}}
- /var/log/pods/{{ template "sumologic.namespace" . }}_{{ template "sumologic.metadata.name.events" . }}*/*/*.log
{{- end -}}

{{- define "events.statefulset.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.otelevents.statefulset.nodeSelector)}}
{{- end -}}

{{- define "events.statefulset.tolerations" -}}
{{- if .Values.otelevents.statefulset.tolerations -}}
{{- toYaml .Values.otelevents.statefulset.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "events.statefulset.affinity" -}}
{{- if .Values.otelevents.statefulset.affinity -}}
{{- toYaml .Values.otelevents.statefulset.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}