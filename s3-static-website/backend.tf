terraform {

  backend "s3" {
    bucket       = "account-vending-terraform-state"
    key          = "day-one-backend/terraform.tfstate"
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
}