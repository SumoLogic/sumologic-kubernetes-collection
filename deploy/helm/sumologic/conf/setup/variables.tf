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

variable "create_fields" {
  description = "If set, Terraform will attempt to create fields at Sumo Logic"
  type        = bool
  default     = true
}
