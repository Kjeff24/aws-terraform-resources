# ECS Cluster Outputs
output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.app_cluster.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.app_cluster.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app_cluster.name
}

# ECS Service Outputs
output "service_id" {
  description = "ECS service ID"
  value       = aws_ecs_service.client_service_management.id
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.client_service_management.name
}

output "service_arn" {
  description = "ECS service ARN"
  value       = aws_ecs_service.client_service_management.id
}

# Task Definition Outputs
output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.client_container_definition.arn
}

output "task_definition_family" {
  description = "Task definition family"
  value       = aws_ecs_task_definition.client_container_definition.family
}

output "task_definition_revision" {
  description = "Task definition revision"
  value       = aws_ecs_task_definition.client_container_definition.revision
}