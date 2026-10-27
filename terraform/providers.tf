terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
  # backend "s3" {
  #     bucket = "value"
  #     key = "value"
  #     region       = var.aws_region
  #     encrypt      = true
  #     use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region
}
