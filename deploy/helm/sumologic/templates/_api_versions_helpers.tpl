{{/*
Use PodDisruptionBudget apiVersion that is available on the cluster

Example Usage:
apiVersion: {{ include "apiVersion.podDisruptionBudget" . }}

*/}}
{{- define "apiVersion.podDisruptionBudget" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1/PodDisruptionBudget" -}}
policy/v1
{{- else if .Capabilities.APIVersions.Has "policy/v1beta1/PodDisruptionBudget" -}}
policy/v1beta1
{{- else -}}
{{- fail "\nPodDisruptionBudget not available on the cluster in neither policy/v1/v1beta1 nor in policy/v1/v1beta1 apiVersion" -}}
{{- end -}}
{{- end -}}
