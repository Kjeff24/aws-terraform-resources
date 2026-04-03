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

variable "enable_logging" {
  description = "Whether to create a logs bucket for CloudFront access logs"
  type        = bool
  default     = false
}

############################
# 🌐 CloudFront Configuration
############################
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be one of PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
  validation {
    condition     = var.default_root_object != "" && !startswith(var.default_root_object, "/")
    error_message = "default_root_object must be a non-empty object name (e.g., index.html) without a leading slash."
  }
}

variable "cloudfront_alias" {
  description = "CNAME alias for CloudFront"
  type        = string
  default     = "cdn.example.com"
  validation {
    condition     = var.cloudfront_alias == "" || can(regex("^([A-Za-z0-9-]+\\.)+[A-Za-z]{2,}$", var.cloudfront_alias))
    error_message = "cloudfront_alias must be a valid DNS name (e.g., cdn.example.com) or empty."
  }
}

variable "logging_prefix" {
  description = "Optional prefix for log files in the logging bucket"
  type        = string
  default     = "cloudfront/"
}

variable "logging_include_cookies" {
  description = "Whether CloudFront should include cookies in the access logs"
  type        = bool
  default     = false
}
