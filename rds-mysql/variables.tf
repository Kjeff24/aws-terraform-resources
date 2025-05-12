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
  default     = "my-site"

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
variable "networking" {
  description = "Networking configuration for the VPC module"
  type = object({
    vpc_cidr             : string
    public_subnet_count  : number
    private_subnet_count : number
    subnet_prefix_length : number
    enable_dns_hostnames : bool
    enable_dns_support   : bool
  })
  default = {
    vpc_cidr             = "10.0.0.0/16"
    public_subnet_count  = 2
    private_subnet_count = 2
    subnet_prefix_length = 24
    enable_dns_hostnames = true
    enable_dns_support   = true
  }

  validation {
    condition     = can(cidrnetmask(var.networking.vpc_cidr))
    error_message = "networking.vpc_cidr must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }

  validation {
    condition     = var.networking.public_subnet_count > 2 && var.networking.private_subnet_count > 2
    error_message = "public_subnet_count and private_subnet_count must both be greater than 2."
  }

  validation {
    condition = (
      var.networking.subnet_prefix_length <= 28 &&
      var.networking.subnet_prefix_length >= tonumber(element(split("/", var.networking.vpc_cidr), 1))
    )
    error_message = "subnet_prefix_length must be between the VPC prefix length and /28."
  }

  validation {
    condition = (
      var.networking.public_subnet_count + var.networking.private_subnet_count
    ) <= pow(
      2,
      var.networking.subnet_prefix_length - tonumber(element(split("/", var.networking.vpc_cidr), 1))
    )
    error_message = "Requested subnets (public + private) exceed capacity for the given VPC CIDR and subnet_prefix_length."
  }

  validation {
    condition     = var.networking.enable_dns_support || (!var.networking.enable_dns_hostnames)
    error_message = "enable_dns_hostnames requires enable_dns_support to be true."
  }
}

############################
# 🗄️ RDS MySQL Inputs
############################
variable "db_config" {
  description = "RDS MySQL configuration"
  type = object({
    engine                      : string
    engine_version              : string
    instance_class              : string
    allocated_storage           : number
    max_allocated_storage       : number
    storage_type                : string
    multi_az                    : bool
    db_name                     : string
    username                    : string
    password                    : optional(string)
    port                        : number
    publicly_accessible         : bool
    deletion_protection         : bool
    backup_retention_period     : number
    backup_window               : string
    maintenance_window          : string
    performance_insights_enabled: bool
    kms_key_id                  : optional(string)
    auto_minor_version_upgrade  : bool
    skip_final_snapshot         : bool
  })

  default = {
    engine                       = "mysql"
    engine_version               = "8.0.35"
    instance_class               = "db.t3.micro"
    allocated_storage            = 20
    max_allocated_storage        = 100
    storage_type                 = "gp3"
    multi_az                     = false
    db_name                      = "appdb"
    username                     = "admin"
    port                         = 3306
    publicly_accessible          = false
    deletion_protection          = true
    backup_retention_period      = 7
    backup_window                = "02:00-03:00"
    maintenance_window           = "Sun:03:00-Sun:04:00"
    performance_insights_enabled = false
    auto_minor_version_upgrade   = true
    skip_final_snapshot          = true
  }

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_config.instance_class))
    error_message = "instance_class must be like db.t3.micro."
  }
  validation {
    condition     = var.db_config.allocated_storage >= 20 && var.db_config.allocated_storage <= 65536
    error_message = "allocated_storage must be between 20 and 65536 GB."
  }
  validation {
    condition     = var.db_config.port == 3306
    error_message = "Only MySQL default port 3306 is supported by this module."
  }
}