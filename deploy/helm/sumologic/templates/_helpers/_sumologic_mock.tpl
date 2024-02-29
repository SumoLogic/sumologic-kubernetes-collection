{{- define "sumologic.sumologic-mock.name.deployment" -}}
{{- template "sumologic.fullname" . }}-mock

{{- end -}}{{- define "sumologic.sumologic-mock.name.service" -}}
{{- template "sumologic.fullname" . }}-mock
{{- end -}}

{{- define "sumologic.labels.app.sumologic-mock" -}}
{{- template "sumologic.fullname" . }}-mock
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
{{- template "sumologic.fullname" . }}-mock
{{- end -}}

{{- define "sumologic-mock.deployment.nodeSelector" -}}
{{- template "nodeSelector" (dict "Values" .Values "nodeSelector" .Values.debug.sumologicMock.deployment.nodeSelector)}}
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

{{- define "sumologic-mock.forward-events"}}
{{- if and (eq .Values.debug.sumologicMock.enabled true) (eq .Values.debug.events.forwardToSumologicMock true) -}}
true
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.forward-metrics-metadata"}}
{{- if and (eq .Values.debug.sumologicMock.enabled true) (eq .Values.debug.metrics.metadata.forwardToSumologicMock true) -}}
true
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.forward-instrumentation"}}
{{- if and (eq .Values.debug.sumologicMock.enabled true) (eq .Values.debug.instrumentation.tracesSampler.forwardToSumologicMock true) -}}
true
{{- end -}}
{{- end -}}

{{- define "sumologic-mock.hostname" -}}
{{ template "sumologic.sumologic-mock.name.service" . }}.{{ template "sumologic.namespace"  . }}.svc.{{ .Values.sumologic.clusterDNSDomain }}.
{{- end -}}

{{- define "sumologic-mock.port" -}}
3000
{{- end -}}

{{- define "sumologic.annotations.app.sumologic-mock.helmsh" -}}
helm.sh/hook: pre-install,pre-upgrade
helm.sh/hook-weight: {{ printf "\"%s\"" . }}
{{- end -}}

{{- define "sumologic-mock.local-mode-enabled" }}
{{- if and (eq .Values.debug.sumologicMock.enabled true) (eq .Values.debug.enableLocalMode true) -}}
true
{{- end -}}
{{- end -}}

{{- define "sumologic.labels.sumologic-mock" -}}
sumologic.com/app: sumologic-mock
{{- end -}}

{{- define "sumologic-mock.receiver-endpoint" -}}
http://{{ template "sumologic-mock.hostname" . }}:{{ template "sumologic-mock.port" . }}/receiver
{{- end -}}
