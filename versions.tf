terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "cloudcart-iitc"

    workspaces {
      name = "sports-store-infrastructure"
    }
  }
}
