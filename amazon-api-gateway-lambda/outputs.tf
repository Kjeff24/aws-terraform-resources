output "api_endpoint" {
  description = "Base URL of the HTTP API"
  value       = module.api_gateway.api_endpoint
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}
