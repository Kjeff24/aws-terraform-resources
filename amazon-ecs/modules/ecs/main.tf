locals {
  ecs_base_env = {
    APP_PORT = tostring(var.ecs_config.container_port)
  }

  ecs_env_map = merge(
    local.ecs_base_env,
    var.ecs_config.environment_variables,
    var.db_password != null && var.db_password != "" ? { DB_PASS = var.db_password } : {}
  )

  ecs_env_list = [
    for k, v in local.ecs_env_map : {
      name  = k
      value = v
    }
  ]

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
