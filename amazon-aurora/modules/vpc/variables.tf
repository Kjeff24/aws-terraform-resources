############################
# 🌍 General Configuration
############################
variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

############################
# 🌐 VPC Configuration
############################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

############################
# 🔒 Security Configuration
############################
variable "aurora_port" {
  description = "Port the Aurora cluster listens on (3306 for MySQL, 5432 for PostgreSQL)"
  type        = number
}
