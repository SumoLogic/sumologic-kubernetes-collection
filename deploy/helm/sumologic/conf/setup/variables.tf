variable "cluster_name" {
  type  = string
  default = "{{ template "sumologic.clusterNameReplaceSpaceWithDash" . }}"
}

variable "collector_name" {
  type  = string
  {{- if .Values.sumologic.collectorName }}
  default = "{{ .Values.sumologic.collectorName }}"
  {{- else }}
  default = "{{ template "sumologic.clusterNameReplaceSpaceWithDash" . }}"
  {{- end }}
}

variable "namespace_name" {
  type  = string
  default = "{{ .Release.Namespace }}"
}