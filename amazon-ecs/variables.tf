############################
# 🌐 General Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "region must be a valid AWS region identifier (e.g., eu-west-1)."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "my-cognito-project"

  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.project_name)) &&
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 20
    )
    error_message = "project_name must be 3-20 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "Static Website Hosting"
  }
}

############################
# 🌐 VPC Configuration
############################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

############################
# ⚙️ ECS Configuration
############################
variable "ecs_config" {
  description = "ECS cluster, service, task, and scaling configuration"
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

variable "health_check_path" {
  description = "Health check path for the ALB target group"
  type        = string
  default     = "/health"
}

variable "db_password" {
  description = "Database password passed to the ECS container as an environment variable"
  type        = string
  sensitive   = true
  default     = null
}