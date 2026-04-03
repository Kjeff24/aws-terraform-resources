/*
Module: ECS Cluster, Task Definition, and Service

Description:
- Provisions an ECS cluster with CloudWatch container insights, a Fargate task
  definition for the web app container, a log group, and an ECS service wired to
  an ALB target group. Environment variables include Aurora connection details
  with optional Secrets Manager integration for DB password.

Creates:
- aws_ecs_cluster.app_cluster
- aws_cloudwatch_log_group.ecs_logs
- aws_ecs_task_definition.client_container_definition
- aws_ecs_service.client_service_management

Inputs:
- var.tags (map(string))
- var.region (string)
- var.private_subnet_ids (list(string))
- var.security_group_id (string)
- var.target_group_arn (string)
- var.execution_role_arn (string)
- var.task_role_arn (string)
- var.health_check_path (string)
- var.db_password (string | null)
- var.ecs_config (object):
  - cluster_name (string)
  - service_name (string)
  - container_name (string)
  - container_image (string)
  - container_port (number)
  - network_mode (string)            e.g., "awsvpc"
  - task_cpu (number|string)         Fargate CPU units
  - task_memory (number|string)      Fargate memory
  - desired_count (number)
  - environment_variables (map(string))

Notes:
- Service desired_count is ignored in lifecycle to allow external autoscaling policies.
- Fargate launch type with awsvpc networking (no public IP) on private subnets.
- Container health check pings http://localhost:${var.ecs_config.container_port}${var.health_check_path}.
*/

locals {
  ecs_base_env = {
    APP_PORT = tostring(var.ecs_config.container_port)
  }

  ecs_env_map = merge(
    local.ecs_base_env,
    var.ecs_config.environment_variables,
  )

  ecs_env_list = [
    for k, v in local.ecs_env_map : {
      name  = k
      value = v
    }
  ]

}

# CloudWatch Log Group for ECS Logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.ecs_config.service_name}"
  retention_in_days = 7

  tags = {
    Name         = "${var.ecs_config.service_name}-logs"
    ResourceName = "ECS-LogGroup"
    Type         = "Container-Logging"
  }
}

# ECS Cluster for Container Orchestration
resource "aws_ecs_cluster" "app_cluster" {
  name = var.ecs_config.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name         = var.ecs_config.cluster_name
    ResourceName = "ECS-Web-Cluster"
    Type         = "Container-Orchestration"
  }
}

# ECS Task Definition - Client Container
resource "aws_ecs_task_definition" "client_container_definition" {
  family                   = var.ecs_config.service_name
  network_mode             = var.ecs_config.network_mode
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_config.task_cpu
  memory                   = var.ecs_config.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.ecs_config.container_name}"
      image     = var.ecs_config.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.ecs_config.container_port
          protocol      = "tcp"
        }
      ]

      environment = local.ecs_env_list

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "${var.ecs_config.service_name}"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.ecs_config.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      # Resource limits
      memory = var.ecs_config.task_memory
      cpu    = var.ecs_config.task_cpu
    }
  ])

  tags = {
    Name         = "${var.ecs_config.service_name}-task"
    ResourceName = "ECS-TaskDefinition"
    Type         = "Container-Task"
  }
}

# ECS Service - Manages running containers
resource "aws_ecs_service" "client_service_management" {
  name            = var.ecs_config.service_name
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.client_container_definition.arn
  desired_count   = var.ecs_config.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.ecs_config.container_name
    container_port   = var.ecs_config.container_port
  }

  # Ensure ALB target group is created before service
  depends_on = [var.target_group_arn]

  # Enable service discovery if needed
  enable_execute_command = true

  tags = {
    Name         = "${var.ecs_config.service_name}-service"
    ResourceName = "ECS-Service"
    Type         = "Container-Service"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}