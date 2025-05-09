terraform {

  backend "s3" {
    bucket       = "aws-terraform-projects-state-bucket"
    key          = "ec2-instance/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}