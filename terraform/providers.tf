terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
  backend "s3" {
    # passing the commented values from terraform init in GitHub Actions using
    # -backend-config flag
    #   bucket = var.bucket_name
    #   key = var.bucket_key
    #   region       = var.aws_region
      encrypt      = true
      use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
