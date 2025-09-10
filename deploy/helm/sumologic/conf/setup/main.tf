terraform {
  required_providers {
    sumologic = {
      source  = "sumologic/sumologic"
      version = ">= 3.0.0, <= 3.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
  }
}
