############################
# IAM Role for Glue Service
############################
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

#   tags = var.tags
}

############################
# Glue Service Policy
############################
resource "aws_iam_role_policy" "glue_service_policy" {
  name = "${var.project_name}-glue-service-policy"
  role = aws_iam_role.glue_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${var.raw_data_bucket_arn}",
          "${var.raw_data_bucket_arn}/*",
          "${var.processed_data_bucket_arn}",
          "${var.processed_data_bucket_arn}/*"
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
          "glue:UpdateTable"
        ]
        Resource = "*"
      }
    ]
  })
}

############################
# CloudWatch Log Group
############################
resource "aws_cloudwatch_log_group" "glue_logs" {
  name              = "/aws-glue/${var.project_name}"
  retention_in_days = var.log_retention_days

#   tags = var.tags
}
