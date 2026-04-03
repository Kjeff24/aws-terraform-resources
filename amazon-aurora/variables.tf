############################
# 🌍 General Configuration
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
  default     = "my-aurora"
  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.project_name)) &&
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 20
    )
    error_message = "project_name must be 3-20 characters, letters, numbers, and hyphens only."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "Amazon Aurora"
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
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

############################
# 🗄️ Aurora Configuration
############################
variable "aurora_config" {
  description = "Aurora cluster configuration. Set serverless_v2_scaling to enable Serverless v2; leave null for provisioned instances."
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    instance_count = number
    database_name  = string
    master_username = string
    serverless_v2_scaling = optional(object({
      min_capacity = number
      max_capacity = number
    }))
  })
  default = {
    engine          = "aurora-postgresql"
    engine_version  = "15.4"
    instance_class  = "db.r6g.large"
    instance_count  = 2
    database_name   = "appdb"
    master_username = "postgres"
    serverless_v2_scaling = null
  }
  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.aurora_config.engine)
    error_message = "aurora_config.engine must be \"aurora-mysql\" or \"aurora-postgresql\"."
  }
}
