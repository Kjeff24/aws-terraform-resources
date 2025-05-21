variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_public_sg_id" {
  description = "The ID of the security group associated with the public-facing Application Load Balancer (ALB)."
  type        = string
}

variable "app_port" {
  description = "Port the application runs on (e.g., 80, 443, or 8080)"
  type        = number
}

variable "alb_settings" {
  description = "An object containing ALB-specific settings used by the module"
  type = object({
    listener_port       = number
    health_check_path   = string
    healthy_threshold   = number
    unhealthy_threshold = number
    timeout             = number
    interval            = number
  })
}
