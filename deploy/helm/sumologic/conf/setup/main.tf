terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = ">= 3.0.0, < 3.1.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
  }
}
