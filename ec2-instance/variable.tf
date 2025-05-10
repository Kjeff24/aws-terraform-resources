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

############################
# � Security Group Settings
############################
variable "vpc_id" {
  description = "ID of the VPC where the EC2 security group will be created"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to access SSH (port 22)"
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = alltrue([for c in var.ssh_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "All entries in ssh_allowed_cidrs must be valid CIDR blocks (e.g., 203.0.113.0/24)."
  }
}

variable "http_allowed_cidrs" {
  description = "List of CIDR blocks allowed to access HTTP (port 80)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.http_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "All entries in http_allowed_cidrs must be valid CIDR blocks (e.g., 0.0.0.0/0)."
  }
}

############################
# �🖥️ EC2 Configuration
############################
variable "key_pair_config" {
  description = "EC2 configuration including key pair settings and generation options"
  type = object({
    enabled              : bool
    key_pair_name         : string
    generate_key_pair     : bool
    public_key            : string
    public_key_path       : string
    key_algorithm         : string   # ED25519 | RSA | ECDSA
    rsa_bits              : number   # used when RSA
    ecdsa_curve           : string   # P256 | P384 | P521 (when ECDSA)
    save_private_key_path : string   # optional, only when generating
    save_public_key_path  : string   # optional, for convenience
  })

  default = {
    enabled              = true
    key_pair_name         = "ec2-key"
    generate_key_pair     = false
    public_key            = ""
    public_key_path       = ""
    key_algorithm         = "ED25519"
    rsa_bits              = 4096
    ecdsa_curve           = "P256"
    save_private_key_path = ""
    save_public_key_path  = ""
  }

  # Exactly one of public_key or public_key_path must be provided when not generating;
  # when generating, neither must be provided.
  validation {
    condition = (
      var.key_pair_config.enabled
      ? (
          var.key_pair_config.generate_key_pair
          ? (length(var.key_pair_config.public_key) == 0 && length(var.key_pair_config.public_key_path) == 0)
          : ((length(var.key_pair_config.public_key) > 0) != (length(var.key_pair_config.public_key_path) > 0))
        )
      : true
    )
    error_message = "When enabled and generate_key_pair=false, provide exactly one of public_key or public_key_path. When enabled and generate_key_pair=true, do not set either."
  }

  # Algorithm must be one of the supported values.
  validation {
    condition     = var.key_pair_config.enabled ? contains(["ED25519", "RSA", "ECDSA"], upper(var.key_pair_config.key_algorithm)) : true
    error_message = "key_pair_config.key_algorithm must be one of: ED25519, RSA, ECDSA."
  }

  # RSA must be >= 2048 bits if selected.
  validation {
    condition     = var.key_pair_config.enabled ? (upper(var.key_pair_config.key_algorithm) != "RSA" || var.key_pair_config.rsa_bits >= 2048) : true
    error_message = "For RSA, rsa_bits must be >= 2048."
  }

  # ECDSA curve validation when ECDSA selected.
  validation {
    condition     = var.key_pair_config.enabled ? (upper(var.key_pair_config.key_algorithm) != "ECDSA" || contains(["P256", "P384", "P521"], upper(var.key_pair_config.ecdsa_curve))) : true
    error_message = "For ECDSA, ecdsa_curve must be one of: P256, P384, P521."
  }

  # If saving a private key, we must be generating it.
  validation {
    condition     = var.key_pair_config.enabled ? ((length(var.key_pair_config.save_private_key_path) == 0) || var.key_pair_config.generate_key_pair) : true
    error_message = "save_private_key_path can only be set when generate_key_pair=true."
  }

  # If disabled, we should not be generating keys
  validation {
    condition     = var.key_pair_config.enabled || (var.key_pair_config.enabled == false && var.key_pair_config.generate_key_pair == false)
    error_message = "When key pair module is disabled, generate_key_pair must be false."
  }
}

############################
# 🧩 EC2 Instance settings
############################
variable "instance_config" {
  description = "Configuration for the EC2 instance module"
  type = object({
    ami_id                  : string
    instance_type           : string
    subnet_id               : string
    security_group_ids      : list(string)
    key_name                : string
    associate_public_ip     : bool
    iam_instance_profile    : string
    root_volume_size_gb     : number
    root_volume_type        : string
    disable_api_termination : bool
  })
}
