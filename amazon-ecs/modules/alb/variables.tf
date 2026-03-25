############################
# 🌍 General Configuration
############################
variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

############################
# 🌐 Networking
############################
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets for the ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

############################
# ⚙️ ALB Configuration
############################
variable "container_port" {
  description = "Port the ECS container listens on (used for target group)"
  type        = number
}

variable "health_check_path" {
  description = "Path for the ALB target group health check"
  type        = string
  default     = "/health"
}
