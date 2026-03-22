############################
# 🌍 General Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}


############################
# IAM Roles
############################
variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

############################
# Networking Configuration
############################
variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

# ==============================
# ECS Configuration
# ==============================
variable "ecs_config" {
  description = "ECS cluster, service, and scaling configuration"
  type = object({
    cluster_name          = string
    service_name          = string
    network_mode          = string
    container_image       = string
    container_name        = string
    container_port        = number
    task_cpu              = number
    task_memory           = number
    desired_count         = number
    min_capacity          = number
    max_capacity          = number
    environment_variables = map(string)
  })
}

variable "db_password" {
  type        = string
  description = "Aurora database password"
}

variable "aurora_cluster_endpoint" {
  type        = string
  description = "Endpoint of the Aurora cluster"
}

variable "aurora_cluster_port" {
  description = "The Aurora cluster port"
  type        = string
}

variable "aurora_cluster_database_name" {
  description = "The database name"
  type        = string
}

variable "aurora_cluster_master_username" {
  description = "The master username for the database"
  type        = string
}

variable "aurora_credentials_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret for Aurora credentials"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
}