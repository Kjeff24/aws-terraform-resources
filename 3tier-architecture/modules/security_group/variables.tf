variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
variable "vpc_id" {
  description = "App SG"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR bloc"
  type = string
}

variable "app_port" {
  description = "Port the application runs on (e.g., 80, 443, or 8080)"
  type        = number
}

variable "db_port" {
  description = "Database port number (e.g., 5432 for PostgreSQL, 3306 for MySQL)"
  type        = number
}