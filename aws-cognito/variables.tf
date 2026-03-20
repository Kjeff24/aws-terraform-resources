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

variable "user_pool_settings" {
  description = "Configuration for Cognito user pool, including verification, username attributes, password policy, and schema"
  type = object({
    auto_verified_attributes = list(string)
    username_attributes      = list(string)
    password_policy = object({
      min_length         = number
      require_uppercase  = bool
      require_lowercase  = bool
      require_numbers    = bool
      require_symbols    = bool
      temp_validity_days = number
    })
    user_pool_schema = list(object({
      name                = string
      attribute_data_type = string
      mutable             = bool
      required            = bool
    }))
  })

  default = {
    auto_verified_attributes = ["email"]
    username_attributes      = ["email"]
    password_policy = {
      min_length         = 8
      require_uppercase  = true
      require_lowercase  = true
      require_numbers    = true
      require_symbols    = true
      temp_validity_days = 7
    }
    user_pool_schema = [
      { name = "email", attribute_data_type = "String", mutable = false, required = true },
      { name = "role", attribute_data_type = "String", mutable = false, required = false }
    ]
  }

  validation {
    condition     = var.user_pool_settings.password_policy.min_length >= 8 && length(var.user_pool_settings.username_attributes) > 0
    error_message = "user_pool_settings invalid: password minimum length must be >= 8 and username_attributes must include at least one attribute."
  }
}