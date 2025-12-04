terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "iacws"

  default_tags {
    tags = {
      Environment = "Test"
      Managed_by  = "OpenTofu"
      User = "jolan"
    }
  }
}