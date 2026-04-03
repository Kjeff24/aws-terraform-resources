# Amazon ECS

Terraform configuration that provisions a complete Fargate-based ECS workload, including networking, load balancing, IAM roles, and the ECS cluster and service.

## Architecture

```
Internet
   │
   ▼
[ALB] ── public subnets (eu-west-1a, eu-west-1b)
   │
   ▼
[ECS Fargate Service] ── private subnets
   │
   ▼
[NAT Gateway] ── outbound internet access
```

## Modules

| Module | Description |
|---|---|
| `modules/vpc` | VPC, subnets, IGW, NAT Gateway, route tables, security groups |
| `modules/alb` | Application Load Balancer, HTTP listener, target group |
| `modules/iam` | ECS task execution role and task role |
| `modules/ecs` | ECS cluster, task definition, Fargate service, CloudWatch logs |

## Resources Created

### VPC
| Resource | Description |
|---|---|
| `aws_vpc` | VPC with DNS support enabled |
| `aws_internet_gateway` | Internet gateway attached to the VPC |
| `aws_subnet` (public) | Public subnets across availability zones |
| `aws_subnet` (private) | Private subnets across availability zones |
| `aws_eip` | Elastic IP for the NAT Gateway |
| `aws_nat_gateway` | NAT Gateway in the first public subnet |
| `aws_route_table` (public) | Routes internet traffic via IGW |
| `aws_route_table` (private) | Routes outbound traffic via NAT Gateway |
| `aws_security_group` (alb) | Allows HTTP/HTTPS inbound from the internet |
| `aws_security_group` (ecs) | Allows inbound only from the ALB security group |

### ALB
| Resource | Description |
|---|---|
| `aws_lb` | Internet-facing Application Load Balancer |
| `aws_lb_target_group` | IP-based target group with health checks |
| `aws_lb_listener` | HTTP listener on port 80, forwards to target group |

### IAM
| Resource | Description |
|---|---|
| `aws_iam_role` (execution) | Pulls images, reads secrets, ships logs to CloudWatch |
| `aws_iam_role` (task) | In-container permissions: logs, metrics, SSM exec, Secrets Manager |

### ECS
| Resource | Description |
|---|---|
| `aws_ecs_cluster` | ECS cluster with CloudWatch Container Insights enabled |
| `aws_ecs_task_definition` | Fargate task definition with container and log configuration |
| `aws_ecs_service` | Fargate service wired to ALB target group on private subnets |
| `aws_cloudwatch_log_group` | Log group with 7-day retention |

## Prerequisites

- Terraform >= 1.x
- AWS provider `~> 6.0`
- An S3 bucket named `account-vending-terraform-state` in `eu-west-1` for remote state

## Backend

```hcl
backend "s3" {
  bucket       = "account-vending-terraform-state"
  key          = "amazon-ecs/terraform.tfstate"
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

## Variables

### General

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `eu-west-1` | AWS region for deployment |
| `project_name` | `string` | `my-ecs-app` | Used for resource naming (3–20 chars) |
| `tags` | `map(string)` | See below | Common tags applied to all resources |

### VPC

| Variable | Type | Default | Description |
|---|---|---|---|
| `vpc_cidr` | `string` | `10.0.0.0/16` | CIDR block for the VPC |
| `availability_zones` | `list(string)` | `["eu-west-1a", "eu-west-1b"]` | AZs for subnet deployment |
| `public_subnet_cidrs` | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | CIDRs for public subnets |
| `private_subnet_cidrs` | `list(string)` | `["10.0.3.0/24", "10.0.4.0/24"]` | CIDRs for private subnets |

### ECS

| Variable | Type | Default | Description |
|---|---|---|---|
| `health_check_path` | `string` | `/health` | ALB target group health check path |
| `ecs_config` | `object` | See below | Full ECS cluster, service, and task configuration |

**`ecs_config` fields:**

| Field | Type | Description |
|---|---|---|
| `cluster_name` | `string` | ECS cluster name |
| `service_name` | `string` | ECS service name |
| `network_mode` | `string` | Network mode (use `awsvpc` for Fargate) |
| `container_image` | `string` | Docker image URI |
| `container_name` | `string` | Container name |
| `container_port` | `number` | Port the container listens on |
| `task_cpu` | `number` | Fargate CPU units (e.g. `256`, `512`, `1024`) |
| `task_memory` | `number` | Fargate memory in MB (e.g. `512`, `1024`) |
| `desired_count` | `number` | Initial number of running tasks |
| `min_capacity` | `number` | Minimum number of tasks for autoscaling |
| `max_capacity` | `number` | Maximum number of tasks for autoscaling |
| `environment_variables` | `map(string)` | Environment variables injected into the container |

## Notes

- **Private subnets only** — ECS tasks run in private subnets with no public IPs; outbound traffic routes via the NAT Gateway.
- **Fargate** — no EC2 instances to manage; CPU and memory are specified at the task level.
- **Desired count** — `ignore_changes = [desired_count]` is set on the ECS service to allow external autoscaling policies to manage task count without Terraform drift.
- **SSM Exec** — `enable_execute_command = true` is set on the service, allowing `aws ecs execute-command` for container debugging.
