AWS Terraform Projects
======================

Collection of Terraform examples for common AWS patterns. Each folder is a self-contained project with its own variables and backends. The list below includes current and planned projects.

Project roadmap
---------------

🟢 Beginner-Level Projects
1. 📁 s3-static-website — Host a static website using S3, enable static website hosting, add CloudFront as CDN, and configure Route 53 for a custom domain.
2. 📁 ec2-instance — Provision an EC2 instance with a key pair and security group allowing SSH and HTTP access, and output the instance’s public IP.
3. 📁 vpc-networking — Create a VPC with public and private subnets, Internet Gateway, NAT Gateway, and route tables for network isolation.
4. 📁 iam-roles-users — Automate the creation of IAM users, roles, groups, and policies with least privilege principles.
5. 📁 rds-mysql — Deploy a secure MySQL RDS instance in a private subnet with backup and maintenance configurations.

🟡 Intermediate-Level Projects
1. 📁 3tier-architecture — Build a 3-tier web application setup: ALB (public), EC2 app servers (private), and RDS database (private) with proper networking and security.
2. 📁 serverless-api — Deploy a fully managed REST API using API Gateway, AWS Lambda, and DynamoDB, with environment variables stored in SSM Parameter Store.
3. 📁 ecs-fargate-cluster — Provision an ECS cluster running containerized applications on Fargate with CloudWatch logging and load balancing.
4. 📁 cloudwatch-alerts — Set up CloudWatch alarms to monitor EC2, RDS, or Lambda metrics and send notifications via SNS topics.
5. 📁 ebs-snapshot-automation — Automate EBS snapshot creation and cleanup using EventBridge, Lambda, and SNS notifications.
6. 📁 aws-glue-csv-to-json-etl — End-to-end AWS Glue ETL: create a Glue crawler, build a Glue ETL script, set up an automatic workflow, and convert CSV files in S3 to JSON outputs.

🔵 Advanced-Level Projects
1. 📁 multi-region-dr — Implement a disaster recovery setup by replicating DynamoDB tables, S3 buckets, and Lambda functions across multiple AWS regions with Route 53 failover.
2. 📁 serverless-ecommerce — Design a serverless backend for an e-commerce app using API Gateway, Lambda, DynamoDB, SQS, and SNS for event-driven workflows.
3. 📁 eks-cluster — Create an Elastic Kubernetes Service (EKS) cluster with worker nodes, autoscaling groups, and IAM roles for service accounts.
4. 📁 cicd-pipeline — Build a CI/CD pipeline using CodePipeline and CodeBuild to automate testing and deployment from GitHub.
5. 📁 cloudfront-alb-s3 — Host a frontend (React or Angular) on S3 and CloudFront with SSL, while routing backend traffic through an Application Load Balancer.
6. 📁 centralized-logging — Aggregate logs from EC2, Lambda, and other services into CloudWatch Logs, export to S3, and analyze with Athena.
7. 📁 vpc-peering — Connect multiple VPCs or AWS accounts securely using VPC Peering or Transit Gateway, and configure routing tables for communication.

How to use
----------
1. Install Terraform and configure AWS credentials (`aws configure` or environment variables).
2. Choose a project folder, then run: `terraform init`, `terraform plan`, `terraform apply`.
3. To clean up, run `terraform destroy` in the same folder.

Notes
-----
- Each project keeps its own `backend.tf`; adjust state storage to match your S3 bucket/DynamoDB settings.
- Review the `variables*.tf` files in each project for required inputs before applying.
