variable "collector_name" {
  type  = string
}

variable "namespace_name" {
  type  = string
  default = "{{ template "sumologic.namespace" . }}"
}

variable "create_fields" {
  description = "If set, Terraform will attempt to create fields at Sumo Logic"
  type        = bool
  default     = true
}

variable "fields" {
  description = "Log fields to create."
  type = list(string)
}
