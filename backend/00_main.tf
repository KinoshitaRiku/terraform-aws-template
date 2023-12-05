terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "local" {}
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      env        = var.env
      repogitory = "terraform-aws-template"
      directory  = "frontend"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"

  default_tags {
    tags = {
      env = var.env
    }
  }
}

data "aws_caller_identity" "current" {}

data "external" "generate_date" {
  program = ["bash", "${path.module}/scripts/generate_date.sh"]
}
