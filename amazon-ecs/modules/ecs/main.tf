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