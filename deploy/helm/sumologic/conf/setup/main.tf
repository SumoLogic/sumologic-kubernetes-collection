terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = ">= 3.2.5, < 3.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
  }
}
