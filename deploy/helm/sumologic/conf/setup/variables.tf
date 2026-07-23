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

variable "use_extension" {
  description = "If set, use SumoLogic extension instead of HTTP sources. An installation token is created automatically."
  type        = bool
  default     = false
}

variable "extension_secret_name" {
  description = "Name of the Kubernetes secret that stores the installation token for extension mode."
  type        = string
  default     = "sumologic-extension"
}

variable "provided_installation_token" {
  description = "Whether a pre-existing installation token was provided via Helm values. When true, Terraform skips token creation."
  type        = bool
  default     = false
}
