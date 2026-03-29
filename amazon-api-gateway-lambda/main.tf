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
