############################
# 🌍 General Configuration
############################
variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

############################
# ⚡ Lambda
############################
variable "lambda_function_name" {
  description = "Name of the Lambda function to integrate with"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  type        = string
}

############################
# 🌐 API Gateway Configuration
############################
variable "api_gateway_config" {
  description = "Configuration for the HTTP API Gateway"
  type = object({
    stage_name       = string
    auto_deploy      = bool
    throttling_burst = number
    throttling_rate  = number
  })
}
