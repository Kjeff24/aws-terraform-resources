output "api_id" {
  description = "ID of the HTTP API"
  value       = aws_apigatewayv2_api.main.id
}

output "api_endpoint" {
  description = "Base URL of the HTTP API"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the HTTP API (used for Lambda permissions)"
  value       = aws_apigatewayv2_api.main.execution_arn
}
