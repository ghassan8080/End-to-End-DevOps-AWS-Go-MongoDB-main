terraform {
  required_version = ">= 1.0, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}
