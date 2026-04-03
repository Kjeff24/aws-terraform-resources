/*
Root: Amazon API Gateway + Lambda

Description:
- Wires together the iam, lambda, and api_gateway modules to provision a
  serverless HTTP API backed by a Lambda function.

Module call order:
  iam  →  lambda      (depends on execution role ARN)
  lambda  →  api_gateway  (depends on function name and invoke ARN)
*/

module "iam" {
  source = "./modules/iam"

  region       = var.region
  project_name = var.project_name
}

module "lambda" {
  source = "./modules/lambda"

  region             = var.region
  project_name       = var.project_name
  execution_role_arn = module.iam.lambda_execution_role_arn
  lambda_config      = var.lambda_config
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name         = var.project_name
  lambda_function_name = module.lambda.function_name
  lambda_invoke_arn    = module.lambda.invoke_arn
  api_gateway_config   = var.api_gateway_config
}
