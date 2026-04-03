/*
Module: IAM Role for Lambda

Description:
- Provisions the IAM execution role used by the Lambda function, with the
  AWS-managed basic execution policy for CloudWatch Logs access.

Creates:
- aws_iam_role.lambda_execution_role
- aws_iam_role_policy_attachment.lambda_basic_execution

Inputs:
- var.region (string)
- var.project_name (string)

Notes:
- The basic execution policy grants lambda:InvokeFunction and logs permissions.
- Extend with additional inline policies for downstream AWS service access.
*/

# 🔐 Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach AWS-managed basic execution policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
