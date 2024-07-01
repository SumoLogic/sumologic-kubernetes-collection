terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = ">= 2.31.0, < 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31.0"
    }
  }
}
