############################
# 🌍 General Configuration
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
  default     = "my-api"
  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.project_name)) &&
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 20
    )
    error_message = "project_name must be 3-20 characters, letters, numbers, and hyphens only."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "API Gateway Lambda"
  }
}

############################
# ⚡ Lambda Configuration
############################
variable "lambda_config" {
  description = "Configuration for the Lambda function"
  type = object({
    runtime       = string
    handler       = string
    filename      = string
    timeout       = number
    memory_size   = number
    architectures = list(string)
    environment_variables = map(string)
  })
  default = {
    runtime       = "python3.12"
    handler       = "index.handler"
    filename      = "lambda.zip"
    timeout       = 30
    memory_size   = 128
    architectures = ["arm64"]
    environment_variables = {}
  }
}

############################
# 🌐 API Gateway Configuration
############################
variable "api_gateway_config" {
  description = "Configuration for the HTTP API Gateway"
  type = object({
    stage_name         = string
    auto_deploy        = bool
    throttling_burst   = number
    throttling_rate    = number
  })
  default = {
    stage_name       = "$default"
    auto_deploy      = true
    throttling_burst = 100
    throttling_rate  = 50
  }
}
