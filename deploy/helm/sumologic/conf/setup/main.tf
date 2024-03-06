terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = ">= 2.28.3, < 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.4"
    }
  }
}
