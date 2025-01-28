terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" # Specify the desired version for the random provider
    }
  }
}

provider "aws" {
  region = var.region
}