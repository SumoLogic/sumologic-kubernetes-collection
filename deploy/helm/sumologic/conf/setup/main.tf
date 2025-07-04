terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = "3.0.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
  }
}
