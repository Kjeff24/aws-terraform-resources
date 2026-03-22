/*
IAM Module - Permissions for AWS Glue and Athena

This module creates IAM resources required for the integrated solution:
- Glue Service Role: Role that Glue assumes to access AWS resources
- Athena User Role: Role for users/EC2 instances to run Athena queries
- IAM Policies: Grants permissions for S3, Glue Catalog, Athena, and CloudWatch
*/

data "aws_caller_identity" "current" {}

locals {
  glue_arn_prefix   = "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}"
  athena_arn_prefix = "arn:aws:athena:${var.region}:${data.aws_caller_identity.current.account_id}"
}

# IAM Role for Glue Service
resource "aws_iam_role" "glue_service_role" {
  name = "${var.project_name}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-glue-service-role"
  }
}

# Glue Service Policy
locals {
  glue_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.raw_data_bucket_arn,
        "${var.raw_data_bucket_arn}/*",
        var.processed_data_bucket_arn,
        "${var.processed_data_bucket_arn}/*",
        var.query_results_bucket_arn,
        "${var.query_results_bucket_arn}/*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:${var.region}:*:log-group:/aws-glue/*"
    },
    {
      Effect = "Allow"
      Action = [
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetPartitions",
        "glue:CreateTable",
        "glue:UpdateTable",
        "glue:DeleteTable"
      ]
      Resource = [
        "${local.glue_arn_prefix}:catalog",
        "${local.glue_arn_prefix}:database/${var.glue_raw_database_name}",
        "${local.glue_arn_prefix}:table/${var.glue_raw_database_name}/*",
        "${local.glue_arn_prefix}:database/${var.glue_catalog_database_name}",
        "${local.glue_arn_prefix}:table/${var.glue_catalog_database_name}/*"
      ]
    }
  ]
}

resource "aws_iam_role_policy" "glue_service_policy" {
  name = "${var.project_name}-glue-service-policy"
  role = aws_iam_role.glue_service_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.glue_policy_statements
  })
}

# CloudWatch Log Group for Glue
resource "aws_cloudwatch_log_group" "glue_logs" {
  name              = "/aws-glue/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-glue-logs"
  }
}

# IAM Role for Athena users
resource "aws_iam_role" "athena_user_role" {
  name = "${var.project_name}-athena-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-athena-user-role"
  }
}

# IAM Policy for Athena access
locals {
  athena_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.processed_data_bucket_arn,
        "${var.processed_data_bucket_arn}/*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.query_results_bucket_arn,
        "${var.query_results_bucket_arn}/*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "glue:GetDatabase",
        "glue:GetDatabases",
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetPartition",
        "glue:GetPartitions"
      ]
      Resource = [
        "${local.glue_arn_prefix}:catalog",
        "${local.glue_arn_prefix}:database/${var.glue_catalog_database_name}",
        "${local.glue_arn_prefix}:table/${var.glue_catalog_database_name}/*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "athena:BatchGetQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:GetQueryResultsStream",
        "athena:ListQueryExecutions",
        "athena:StartQueryExecution",
        "athena:StopQueryExecution",
        "athena:GetWorkGroup"
      ]
      Resource = "${local.athena_arn_prefix}:workgroup/*"
    },
    {
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:${var.region}:*:log-group:/aws-athena/*"
    }
  ]
}

resource "aws_iam_role_policy" "athena_user_policy" {
  name = "${var.project_name}-athena-user-policy"
  role = aws_iam_role.athena_user_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.athena_policy_statements
  })
}
