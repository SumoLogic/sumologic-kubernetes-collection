{{/*
Use PodDisruptionBudget apiVersion that is available on the cluster

Example Usage:
apiVersion: {{ include "apiVersion.podDisruptionBudget" . }}

*/}}
{{- define "apiVersion.podDisruptionBudget" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1" -}}
policy/v1
{{- else -}}
policy/v1beta1
{{- end -}}
{{- end -}}

{{/*
Use HorizontalPodAutoscaler apiVersion that is available on the cluster

Example Usage:
apiVersion: {{ include "apiVersion.horizontalPodAutoscaler" . }}

*/}}
{{- define "apiVersion.horizontalPodAutoscaler" -}}
{{- if .Capabilities.APIVersions.Has "autoscaling/v2" -}}
autoscaling/v2
{{- else -}}
autoscaling/v2beta2
{{- end -}}
{{- end -}}
