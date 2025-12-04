terraform {
  required_providers {
    aws = {
      source  = "opentofu/aws"
      version = "~> 6.20"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "iacws"
}