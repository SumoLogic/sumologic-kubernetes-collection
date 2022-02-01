terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.13"
    }
  }
}
