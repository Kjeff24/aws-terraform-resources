# Amazon API Gateway + Lambda

Terraform configuration that provisions a serverless HTTP API using Amazon API Gateway (HTTP API v2) backed by an AWS Lambda function.

## Architecture

```
Client
  │
  ▼
[API Gateway HTTP API] ── $default route (all methods/paths)
  │
  ▼
[Lambda Function] ── AWS_PROXY integration
  │
  ▼
[CloudWatch Logs]
```

## Modules

| Module | Description |
|---|---|
| `modules/iam` | Lambda execution role with CloudWatch Logs access |
| `modules/lambda` | Lambda function, log group, and function code packaging |
| `modules/api_gateway` | HTTP API, Lambda integration, default route, stage, and Lambda permission |

## Resources Created

### IAM
| Resource | Description |
|---|---|
| `aws_iam_role` | Lambda execution role |
| `aws_iam_role_policy_attachment` | Attaches `AWSLambdaBasicExecutionRole` managed policy |

### Lambda
| Resource | Description |
|---|---|
| `aws_cloudwatch_log_group` | Log group with 7-day retention (`/aws/lambda/{name}`) |
| `aws_lambda_function` | Lambda function packaged from `lambda_function/` |

### API Gateway
| Resource | Description |
|---|---|
| `aws_apigatewayv2_api` | HTTP API (protocol: HTTP) |
| `aws_apigatewayv2_integration` | AWS_PROXY integration with Lambda (payload format 2.0) |
| `aws_apigatewayv2_route` | `$default` route — catches all methods and paths |
| `aws_apigatewayv2_stage` | Stage with configurable throttling and auto-deploy |
| `aws_lambda_permission` | Grants API Gateway permission to invoke the Lambda function |

## Prerequisites

- Terraform >= 1.x
- AWS provider `~> 6.0`
- An S3 bucket named `account-vending-terraform-state` in `eu-west-1` for remote state

## Backend

```hcl
backend "s3" {
  bucket       = "account-vending-terraform-state"
  key          = "amazon-api-gateway-lambda/terraform.tfstate"
  region       = "eu-west-1"
  use_lockfile = true
}
```

## Usage

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then deploy:

```bash
terraform init
terraform plan
terraform apply
```

Test the API endpoint from the outputs:

```bash
curl $(terraform output -raw api_endpoint)
```

## Lambda Function

The function code lives in `modules/lambda/lambda_function/`. Terraform uses `archive_file` to zip the directory at plan time and uploads it to Lambda automatically. The `source_code_hash` ensures Lambda is updated whenever the code changes.

To add a new runtime, update `lambda_config.runtime` and `lambda_config.handler` in your `terraform.tfvars`, and replace `index.py` with your function code.

## Variables

### General

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `eu-west-1` | AWS region for deployment |
| `project_name` | `string` | `my-api` | Used for resource naming (3–20 chars) |
| `tags` | `map(string)` | See below | Common tags applied to all resources |

### Lambda

| Variable | Type | Default | Description |
|---|---|---|---|
| `lambda_config` | `object` | See below | Lambda function configuration |

**`lambda_config` fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `runtime` | `string` | `python3.12` | Lambda runtime |
| `handler` | `string` | `index.handler` | Function handler (`file.method`) |
| `timeout` | `number` | `30` | Max execution time in seconds |
| `memory_size` | `number` | `128` | Memory allocated in MB |
| `architectures` | `list(string)` | `["arm64"]` | CPU architecture (`x86_64` or `arm64`) |
| `environment_variables` | `map(string)` | `{}` | Environment variables injected into the function |

### API Gateway

| Variable | Type | Default | Description |
|---|---|---|---|
| `api_gateway_config` | `object` | See below | HTTP API configuration |

**`api_gateway_config` fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `stage_name` | `string` | `$default` | Stage name |
| `auto_deploy` | `bool` | `true` | Automatically deploy on change |
| `throttling_burst` | `number` | `100` | Max concurrent requests (burst) |
| `throttling_rate` | `number` | `50` | Sustained requests per second |

## Outputs

| Output | Description |
|---|---|
| `api_endpoint` | Base URL of the HTTP API |
| `lambda_function_name` | Name of the Lambda function |
| `lambda_function_arn` | ARN of the Lambda function |

## Notes

- **AWS_PROXY integration** — API Gateway passes the full HTTP request to Lambda as a structured event (payload format 2.0) and returns the Lambda response directly to the client. No mapping templates required.
- **`$default` route** — catches all HTTP methods and paths, making the Lambda responsible for routing logic if needed.
- **arm64 architecture** — uses Graviton2 by default for lower cost and better performance. Change to `x86_64` if your runtime or dependencies require it.
- **Auto-deploy** — stage changes are deployed automatically; set `auto_deploy = false` for controlled deployments.
