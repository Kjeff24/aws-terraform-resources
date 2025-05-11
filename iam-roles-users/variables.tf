############################
# 🌐 General Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "region must be a valid AWS region identifier (e.g., eu-west-1)."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "my-site"

  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.project_name)) &&
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 20
    )
    error_message = "project_name must be 3-20 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "Static Website Hosting"
  }
}

############################
# 👥 IAM Inputs
############################
variable "groups" {
  description = "IAM groups and their inline least-privilege policies"
  type = map(object({
    inline_policies = optional(map(object({
      description = optional(string)
      statements = list(object({
        effect    = optional(string)
        actions   = list(string)
        resources = list(string)
      }))
    })), {})
  }))
  default = {
    "read-only" = {
      inline_policies = {
        "s3-read-example" = {
          description = "Read-only access to example S3 bucket"
          statements = [
            {
              actions   = ["s3:ListBucket"]
              resources = ["arn:aws:s3:::example-bucket"]
            },
            {
              actions   = ["s3:GetObject"]
              resources = ["arn:aws:s3:::example-bucket/*"]
            }
          ]
        }
      }
    }
  }
}

variable "users" {
  description = "IAM users and their group memberships, tags, and assumable roles"
  type = map(object({
    groups           = optional(list(string), [])
    tags             = optional(map(string), {})
    assumable_roles  = optional(list(string), [])
  }))
  default = {
    "demo" = {
      groups          = ["read-only"]
      tags            = { Purpose = "Demo" }
      assumable_roles = ["ec2-reader"]
    }
  }
}

variable "roles" {
  description = "IAM roles with trust relationships and inline least-privilege policies"
  type = map(object({
    description          = optional(string)
    assume_services      = optional(list(string), [])
    assume_account_ids   = optional(list(string), [])
    max_session_duration = optional(number)
    inline_policies = optional(map(object({
      description = optional(string)
      statements = list(object({
        effect    = optional(string)
        actions   = list(string)
        resources = list(string)
      }))
    })), {})
  }))
  default = {
    "ec2-reader" = {
      description        = "Role for EC2 instances to read from example S3 bucket"
      assume_services    = ["ec2.amazonaws.com"]
      assume_account_ids = []
      inline_policies = {
        "s3-read-example" = {
          statements = [
            {
              actions   = ["s3:ListBucket"]
              resources = ["arn:aws:s3:::example-bucket"]
            },
            {
              actions   = ["s3:GetObject"]
              resources = ["arn:aws:s3:::example-bucket/*"]
            }
          ]
        }
      }
    }
  }
}