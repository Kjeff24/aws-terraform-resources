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
    condition     = var.networking.public_subnet_count > 0 && var.networking.private_subnet_count > 0
    error_message = "public_subnet_count and private_subnet_count must both be greater than 0."
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
