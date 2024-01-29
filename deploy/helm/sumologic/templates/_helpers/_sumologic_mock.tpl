{{- define "sumologic.sumologic-mock.name.deployment" -}}
{{- template "sumologic.fullname" . }}-sumologic-mock

{{- end -}}{{- define "sumologic.sumologic-mock.name.service" -}}
{{- template "sumologic.fullname" . }}-sumologic-mock
{{- end -}}

{{- define "sumologic.labels.app.sumologic-mock" -}}
{{- template "sumologic.fullname" . }}-sumologic-mock
{{- end -}}

{{- define "sumologic.labels.app.sumologic-mock.deployment" -}}
{{ template "sumologic.labels.app.sumologic-mock" . }}
{{- end -}}

{{- define "sumologic.labels.app.sumologic-mock.pod" -}}
{{ template "sumologic.labels.app.sumologic-mock" . }}
{{- end -}}

{{- define "sumologic.labels.app.sumologic-mock.service" -}}
{{ template "sumologic.labels.app.sumologic-mock" . }}
{{- end -}}

{{- define "sumologic.metadata.name.sumologic-mock" -}}
{{- template "sumologic.fullname" . }}-sumologic-mock
{{- end -}}

{{- define "sumologic-mock.deployment.nodeSelector" -}}
{{- if .Values.debug.sumologicMock.deployment.nodeSelector -}}
{{- toYaml .Values.debug.sumologicMock.deployment.nodeSelector -}}
{{- else -}}
{{- template "kubernetes.defaultNodeSelector" . -}}
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.deployment.tolerations" -}}
{{- if .Values.debug.sumologicMock.deployment.tolerations -}}
{{- toYaml .Values.debug.sumologicMock.deployment.tolerations -}}
{{- else -}}
{{- template "kubernetes.defaultTolerations" . -}}
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.deployment.affinity" -}}
{{- if .Values.debug.sumologicMock.deployment.affinity -}}
{{- toYaml .Values.debug.sumologicMock.deployment.affinity -}}
{{- else -}}
{{- template "kubernetes.defaultAffinity" . -}}
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.forward-logs-metadata"}}
{{- if and (eq .Values.debug.sumologicMock.enabled true) (eq .Values.debug.logs.metadata.forwardToSumologicMock true) -}}
true
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.forward-metrics-metadata"}}
{{- if and (eq .Values.debug.sumologicMock.enabled true) (eq .Values.debug.metrics.metadata.print true) -}}
true
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.hostname" -}}
{{ template "sumologic.sumologic-mock.name.service" . }}.{{ template "sumologic.namespace"  . }}
{{- end -}}

{{- define "sumologic-mock.port" -}}
3000
{{- end -}}
