terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
  backend "local" {}
}

provider "aws" {
  region  = "ap-northeast-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  default_tags {
    tags = {
      repogitory = "terraform-aws-template"
      directory  = "oidc"
    }
  }
}
