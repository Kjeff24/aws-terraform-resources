
/*
Module: IAM Roles and Policies for ECS

Description:
- Provisions the IAM roles and policies required by ECS tasks:
  - Execution Role: pulls images, reads secrets, ships logs.
  - Task Role: in-container app permissions (logs, metrics, SSM exec, secrets).

Creates:
- data.aws_caller_identity.current
- aws_iam_role.ecs_task_execution_role
- aws_iam_role_policy_attachment.ecs_task_execution_managed
- aws_iam_role_policy.ecs_execution_secrets_policy
- aws_iam_role.ecs_task_role
- aws_iam_role_policy.ecs_task_basic_policy

Inputs:
- var.project_name (string)
- var.region (string)
- var.tags (map(string))

Notes:
- Both roles trust ecs-tasks.amazonaws.com via assume role policy.
  is derived from data.aws_caller_identity.current.
- The basic task policy includes CloudWatch Logs, custom metrics, SSM exec channels,
  and encrypted secret read access; tighten to least-privilege as needed.
*/

data "aws_caller_identity" "current" {}

# ===============================
# ECS Task Execution Role
# Used by ECS to pull images, fetch secrets, and send logs
# ===============================
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

}

# Attach required AWS-managed policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ===============================
# ECS Task Role (App inside container)
# ===============================
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

}

# Minimal permissions for application containers
resource "aws_iam_role_policy" "ecs_task_basic_policy" {
  name = "${var.project_name}-ecs-task-role-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:*"
      }
    ]
  })
}