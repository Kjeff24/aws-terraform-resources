/*
Module: Lambda Function

Description:
- Zips the local lambda_function/ directory using archive_file and provisions
  a Lambda function with a CloudWatch log group for structured logging.
  Supports configurable runtime, handler, timeout, memory, and environment
  variables.

Creates:
- data.archive_file.lambda_zip
- aws_cloudwatch_log_group.lambda_logs
- aws_lambda_function.main

Inputs:
- var.region (string)
- var.project_name (string)
- var.execution_role_arn (string)
- var.lambda_config (object):
  - runtime (string)
  - handler (string)
  - timeout (number)
  - memory_size (number)
  - architectures (list(string))
  - environment_variables (map(string))

Notes:
- archive_file zips lambda_function/ at plan time; source_code_hash ensures
  Lambda is updated whenever the function code changes.
- Log group is created explicitly to control retention (7 days).
*/

# 📦 Zip the lambda_function directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

# 📋 CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-function"
  retention_in_days = 7

  tags = {
    Name         = "${var.project_name}-lambda-logs"
    ResourceName = "Lambda-LogGroup"
  }
}

# ⚡ Lambda Function
resource "aws_lambda_function" "main" {
  function_name    = "${var.project_name}-function"
  role             = var.execution_role_arn
  runtime          = var.lambda_config.runtime
  handler          = var.lambda_config.handler
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = var.lambda_config.timeout
  memory_size      = var.lambda_config.memory_size
  architectures    = var.lambda_config.architectures

  dynamic "environment" {
    for_each = length(var.lambda_config.environment_variables) > 0 ? [1] : []
    content {
      variables = var.lambda_config.environment_variables
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]

  tags = {
    Name         = "${var.project_name}-function"
    ResourceName = "Lambda-Function"
  }
}
