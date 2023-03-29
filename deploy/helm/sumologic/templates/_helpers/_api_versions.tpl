{{/*
Use PodDisruptionBudget apiVersion that is available on the cluster

Example Usage:
apiVersion: {{ include "apiVersion.podDisruptionBudget" . }}

*/}}
{{- define "apiVersion.podDisruptionBudget" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1/PodDisruptionBudget" -}}
policy/v1
{{- else -}}
policy/v1beta1
{{- end -}}
{{- end -}}
