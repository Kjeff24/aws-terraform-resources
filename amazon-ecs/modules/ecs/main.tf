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
