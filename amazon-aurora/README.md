# Amazon Aurora

Terraform configuration that provisions a production-ready Amazon Aurora cluster supporting both MySQL and PostgreSQL engines, with provisioned or Serverless v2 instances in isolated private subnets.

## Architecture

```
VPC (private subnets only)
  │
  ├── Private Subnet AZ-1
  ├── Private Subnet AZ-2
  └── Private Subnet AZ-3
        │
        ▼
  [Aurora Cluster]
    ├── Writer Instance (instance-1)
    └── Reader Instance (instance-2, ...)
        │
        ▼
  [Secrets Manager] — master password (AWS-managed)
```

## Modules

| Module | Description |
|---|---|
| `modules/vpc` | VPC, private subnets, Aurora security group |
| `modules/aurora` | Subnet group, parameter groups, Aurora cluster and instances |

## Resources Created

### VPC
| Resource | Description |
|---|---|
| `aws_vpc` | VPC with DNS support enabled |
| `aws_subnet` (private) | Private subnets across availability zones |
| `aws_security_group` | Allows inbound on Aurora port from within the VPC CIDR only |

### Aurora
| Resource | Description |
|---|---|
| `aws_db_subnet_group` | Subnet group spanning all private subnets |
| `aws_rds_cluster_parameter_group` | Cluster-level parameter group (engine-derived family) |
| `aws_db_parameter_group` | Instance-level parameter group (engine-derived family) |
| `aws_rds_cluster` | Aurora cluster with encryption and AWS-managed master password |
| `aws_rds_cluster_instance` | One writer + N-1 reader instances |

## Prerequisites

- Terraform >= 1.x
- AWS provider `~> 6.0`
- An S3 bucket named `account-vending-terraform-state` in `eu-west-1` for remote state

## Backend

```hcl
backend "s3" {
  bucket       = "account-vending-terraform-state"
  key          = "amazon-aurora/terraform.tfstate"
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
| `project_name` | `string` | `my-aurora` | Used for resource naming (3–20 chars) |
| `tags` | `map(string)` | See example | Common tags applied to all resources |

### VPC

| Variable | Type | Default | Description |
|---|---|---|---|
| `vpc_cidr` | `string` | `10.0.0.0/16` | CIDR block for the VPC |
| `availability_zones` | `list(string)` | `["eu-west-1a", "eu-west-1b", "eu-west-1c"]` | AZs for subnet deployment |
| `private_subnet_cidrs` | `list(string)` | `["10.0.1.0/24", ...]` | CIDRs for private subnets |

### Aurora

| Variable | Type | Default | Description |
|---|---|---|---|
| `aurora_config` | `object` | See below | Full Aurora cluster configuration |

**`aurora_config` fields:**

| Field | Type | Description |
|---|---|---|
| `engine` | `string` | `"aurora-mysql"` or `"aurora-postgresql"` |
| `engine_version` | `string` | Aurora engine version |
| `instance_class` | `string` | Instance class (e.g. `db.r6g.large`) — ignored for Serverless v2 |
| `instance_count` | `number` | Total number of instances (writer + readers) |
| `database_name` | `string` | Name of the default database |
| `master_username` | `string` | Master username |
| `serverless_v2_scaling` | `object` (optional) | Set to enable Serverless v2; `null` for provisioned |

**`serverless_v2_scaling` fields:**

| Field | Type | Description |
|---|---|---|
| `min_capacity` | `number` | Minimum ACUs (e.g. `0.5`) |
| `max_capacity` | `number` | Maximum ACUs (e.g. `8`) |

## Outputs

| Output | Description |
|---|---|
| `cluster_endpoint` | Writer endpoint |
| `cluster_reader_endpoint` | Reader endpoint |
| `cluster_port` | Port the cluster listens on |
| `database_name` | Default database name |
| `master_user_secret_arn` | ARN of the Secrets Manager secret for the master password |

## Notes

- **Engine flexibility** — port and parameter group family are derived automatically from `engine`: `3306` / `aurora-mysql8.0` for MySQL, `5432` / `aurora-postgresql15` for PostgreSQL.
- **Serverless v2** — set `serverless_v2_scaling` to enable; `instance_class` is automatically overridden to `db.serverless`. Uses `engine_mode = "provisioned"` as required by AWS.
- **AWS-managed password** — `manage_master_user_password = true` delegates password creation and rotation to AWS Secrets Manager; no plaintext passwords in state.
- **Encryption** — storage encryption is enabled by default (`storage_encrypted = true`).
- **Final snapshot** — a final snapshot is taken on cluster deletion (`skip_final_snapshot = false`).
- **Private only** — no IGW or NAT Gateway; Aurora is accessible only from within the VPC.
