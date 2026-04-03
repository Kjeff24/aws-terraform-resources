/*
Module: API Gateway HTTP API

Description:
- Provisions an HTTP API (v2) with a Lambda proxy integration, a default stage
  with throttling, and a Lambda permission allowing API Gateway to invoke the
  function.

Creates:
- aws_apigatewayv2_api.main
- aws_apigatewayv2_integration.lambda
- aws_apigatewayv2_route.default
- aws_apigatewayv2_stage.main
- aws_lambda_permission.api_gateway

Inputs:
- var.project_name (string)
- var.lambda_function_name (string)
- var.lambda_invoke_arn (string)
- var.api_gateway_config (object):
  - stage_name (string)
  - auto_deploy (bool)
  - throttling_burst (number)
  - throttling_rate (number)

Notes:
- Route "$default" catches all methods and paths, forwarding to Lambda.
- Lambda permission is scoped to this API only via source_arn.
*/

# 🌐 HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"

  tags = {
    Name         = "${var.project_name}-http-api"
    ResourceName = "APIGateway-HTTPAPI"
  }
}

# 🔗 Lambda Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
}

# 🛣️ Default Route — catches all methods and paths
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# 🚀 Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.api_gateway_config.stage_name
  auto_deploy = var.api_gateway_config.auto_deploy

  default_route_settings {
    throttling_burst_limit = var.api_gateway_config.throttling_burst
    throttling_rate_limit  = var.api_gateway_config.throttling_rate
  }

  tags = {
    Name         = "${var.project_name}-stage"
    ResourceName = "APIGateway-Stage"
  }
}

# 🔑 Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
