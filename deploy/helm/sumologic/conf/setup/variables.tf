variable "collector_name" {
  type = string
}

variable "namespace_name" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "create_fields" {
  description = "If set, Terraform will attempt to create fields at Sumo Logic"
  type        = bool
  default     = true
}

variable "fields" {
  description = "Log fields to create."
  type        = list(string)
}

variable "collector_fields" {
  description = "Fields to set on the collector."
  type        = map(string)
}

variable "chart_version" {
  description = "The Helm Chart version."
  type        = string
}
