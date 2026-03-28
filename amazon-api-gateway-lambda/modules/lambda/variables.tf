############################
# 🌍 General Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

############################
# 🔐 IAM
############################
variable "execution_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

############################
# ⚡ Lambda Configuration
############################
variable "lambda_config" {
  description = "Configuration for the Lambda function"
  type = object({
    runtime       = string
    handler       = string
    timeout       = number
    memory_size   = number
    architectures = list(string)
    environment_variables = map(string)
  })
}
