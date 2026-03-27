# AWS Terraform Projects

A comprehensive collection of Terraform modules and examples for common AWS infrastructure patterns. Each project is self-contained with its own variables, backends, and documentation.

## 📋 Table of Contents

- [Completed Projects](#completed-projects)
- [Planned Projects](#planned-projects)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Contributing](#contributing)

## ✅ Completed Projects

### 🟢 Beginner-Level Projects

#### 1. [s3-static-website](./s3-static-website/)
Host a static website using S3 with CloudFront CDN distribution. Includes S3 bucket configuration, CloudFront distribution, and optional logging.

**Features:**
- S3 bucket with static website hosting
- CloudFront distribution for global CDN
- Optional CloudFront access logging
- Configurable price classes and caching

#### 2. [ec2-instance](./ec2-instance/)
Provision a secure EC2 instance with SSH key pair generation, security groups, and user data support.

**Features:**
- Automatic SSH key pair generation
- Configurable security groups
- User data script support
- Input validation for instance configuration

#### 3. [vpc-networking](./vpc-networking/)
Create a production-ready VPC with public and private subnets, Internet Gateway, NAT Gateway, and route tables.

**Features:**
- Multi-AZ public and private subnets
- Internet Gateway for public access
- NAT Gateway for private subnet internet access
- Configurable CIDR blocks and subnet counts

#### 4. [iam-roles-users](./iam-roles-users/)
Automate IAM users, groups, and roles creation with least privilege principles and role assumption support.

**Features:**
- IAM users and groups with inline policies
- IAM roles with configurable trust policies
- Cross-account role assumption support
- Least privilege by default

#### 5. [rds-mysql](./rds-mysql/)
Deploy a secure MySQL RDS instance in private subnets with VPC, security groups, and backup configurations.

**Features:**
- RDS MySQL in private subnets
- Automatic password generation
- Backup and maintenance window configuration
- Encryption at rest with optional KMS

### 🟡 Intermediate-Level Projects

#### 6. [3tier-architecture](./3tier-architecture/)
Build a complete 3-tier web application architecture with ALB, EC2 application servers, and RDS database.

**Features:**
- Application Load Balancer (ALB)
- EC2 instances in private subnets
- RDS database in isolated private subnets
- Security groups with least privilege
- Modular architecture for easy customization

#### 7. [aws-glue-etl-pipeline](./aws-glue-etl-pipeline/)
End-to-end AWS Glue ETL pipeline with crawler, ETL jobs, workflows, and optional Lake Formation integration.

**Features:**
- Glue Crawler for schema discovery
- Glue ETL jobs with PySpark/Spark
- Automated workflows (Crawler → Job)
- Data quality checks and reporting
- Time-based partitioning
- Multi-format support (CSV, JSON, Parquet, ORC)
- Optional Lake Formation integration

#### 8. [aws-athena](./aws-athena/)
Set up AWS Athena for interactive SQL queries on data stored in S3 with Glue Data Catalog integration.

**Features:**
- S3 buckets for data storage and query results
- Glue Data Catalog database and tables
- Athena workgroups with encryption and result configuration
- IAM roles and policies for secure access
- Support for partitioned tables
- Multiple workgroup configurations
- Example queries and sample data

#### 9. [amazon-cognito](./amazon-cognito/)
Provision a fully-featured Cognito User Pool with hosted UI, OAuth2/PKCE client, and federated identity providers.

**Features:**
- Cognito User Pool with configurable password policy and schema
- PKCE-ready app client with OAuth2 flows and token validity settings
- Federated IdPs: Google, Facebook, Login with Amazon, Sign in with Apple
- Generic OIDC and SAML provider support (multiple via for_each)
- Hosted UI domain with managed login version support
- Dynamic supported_identity_providers list derived from configured IdPs

#### 10. [amazon-ecs](./amazon-ecs/)
Deploy a complete Fargate-based ECS workload with VPC, ALB, IAM roles, and ECS cluster.

**Features:**
- Modular design: vpc, alb, iam, ecs modules
- ECS Fargate cluster with CloudWatch Container Insights
- Application Load Balancer with HTTP listener and health checks
- Private subnets for ECS tasks with NAT Gateway egress
- IAM execution and task roles with least-privilege policies
- SSM Execute Command support for container debugging

## 🚧 Planned Projects

### Intermediate-Level

- **serverless-api** — Deploy a fully managed REST API using API Gateway, AWS Lambda, and DynamoDB
- **cloudwatch-alerts** — Set up CloudWatch alarms to monitor EC2, RDS, or Lambda metrics
- **ebs-snapshot-automation** — Automate EBS snapshot creation and cleanup using EventBridge and Lambda

### Advanced-Level

- **multi-region-dr** — Implement disaster recovery with multi-region replication
- **serverless-ecommerce** — Design a serverless backend for e-commerce using API Gateway, Lambda, DynamoDB, SQS, and SNS
- **eks-cluster** — Create an Elastic Kubernetes Service (EKS) cluster with worker nodes and autoscaling
- **cicd-pipeline** — Build a CI/CD pipeline using CodePipeline and CodeBuild
- **cloudfront-alb-s3** — Host frontend on S3/CloudFront with backend through ALB
- **centralized-logging** — Aggregate logs from multiple services into CloudWatch and S3
- **vpc-peering** — Connect multiple VPCs or AWS accounts using VPC Peering or Transit Gateway

## 🚀 Getting Started

### Prerequisites

- **Terraform** >= 1.0 (1.5+ recommended)
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create resources

### Quick Start

1. **Choose a project** from the [Completed Projects](#completed-projects) list
2. **Navigate to the project directory**:
   ```bash
   cd <project-name>
   ```
3. **Configure the backend** (if using remote state):
   - Edit `backend.tf` to point to your S3 bucket
   - Or use local state: `terraform init -backend=false`
4. **Review and set variables**:
   - Check `variables.tf` for required inputs
   - Create `terraform.tfvars` or use `-var` flags
   - Some projects include `terraform.tfvars.example` as a template
5. **Initialize and deploy**:
   ```bash
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```
6. **Clean up** when done:
   ```bash
   terraform destroy
   ```

### Configuration

Each project maintains its own:
- `backend.tf` — Terraform state backend configuration (S3 by default)
- `variables.tf` — Input variables with descriptions and defaults
- `outputs.tf` — Output values for created resources
- `README.md` — Project-specific documentation

**Important Notes:**
- Review `variables*.tf` files before applying to understand required inputs
- Adjust `backend.tf` to match your S3 bucket/DynamoDB settings for remote state
- Some projects require existing resources (e.g., S3 bucket for state storage)
- Check individual project READMEs for specific prerequisites and examples

## 📁 Project Structure

```
aws-terraform-projects/
├── README.md                    # This file
├── .gitignore                   # Git ignore rules
│
├── s3-static-website/          # ✅ Static website with CloudFront
├── ec2-instance/               # ✅ EC2 instance provisioning
├── vpc-networking/             # ✅ VPC with subnets and gateways
├── iam-roles-users/            # ✅ IAM automation
├── rds-mysql/                  # ✅ RDS MySQL deployment
├── 3tier-architecture/        # ✅ 3-tier web app architecture
├── aws-glue-etl-pipeline/     # ✅ Glue ETL pipeline
├── aws-athena/                # ✅ Athena analytics
├── amazon-cognito/            # ✅ Cognito authentication
└── amazon-ecs/                # ✅ ECS Fargate workload
```

Each project follows a modular structure:
- `main.tf` — Root module configuration
- `modules/` — Reusable Terraform modules
- `backend.tf` — State backend configuration
- `variables.tf` — Input variables
- `outputs.tf` — Output values
- `README.md` — Project documentation

## 🤝 Contributing

Contributions are welcome! When adding new projects:

1. Follow the existing project structure and naming conventions
2. Include comprehensive `README.md` documentation
3. Add input validation where appropriate
4. Use modular design with reusable modules
5. Include example `terraform.tfvars.example` files
6. Document prerequisites and common use cases

## 📝 License

This project is provided as-is for educational and production use.

## 🔗 Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Note:** These modules create AWS resources that may incur costs. Always review and understand the resources being created before applying. Use `terraform plan` to preview changes.
