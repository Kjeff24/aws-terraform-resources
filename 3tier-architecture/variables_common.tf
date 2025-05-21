############################
# 🌐 General Configuration (moved to variables_common.tf)
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
