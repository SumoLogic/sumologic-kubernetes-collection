terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = "~> 2.18"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.4"
    }
  }
}
