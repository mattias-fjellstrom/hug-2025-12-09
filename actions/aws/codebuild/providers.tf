terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
    }

    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}
