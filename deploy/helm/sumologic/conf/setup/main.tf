terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = "~> 2.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.4"
    }
  }
}
