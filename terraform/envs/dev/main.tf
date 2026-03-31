terraform {
  required_version = "~> 1.14"

  backend "s3" {
    bucket         = "cloudcraft-tfstate-738057517675"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    kms_key_id     = "alias/cloudcraft-tfstate"
    dynamodb_table = "cloudcraft-tfstate-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
