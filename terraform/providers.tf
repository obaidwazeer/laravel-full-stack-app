terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
  backend "s3" {
      bucket = var.bucket_name
      key = var.bucket_key
      region       = var.aws_region
      encrypt      = true
      use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
