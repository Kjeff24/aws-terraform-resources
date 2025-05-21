############################
# 🌐 VPC / Networking Configuration (moved to variables_networking.tf)
############################
variable "networking" {
  description = <<EOF
Networking configuration for the VPC module. This object groups VPC and subnet
settings (CIDR, subnet sizing and counts, and DNS options). Validation rules are
applied below to ensure the values are consistent (for example, subnet prefix
length must be within the VPC mask range, and the requested number of subnets
must fit within the VPC CIDR).

Attributes:
  - vpc_cidr (string): IPv4 CIDR block for the VPC (e.g., "10.0.0.0/16").
  - public_subnet_count (number): How many public subnets to create (must be >0).
  - private_subnet_count (number): How many private subnets to create (must be >0).
  - subnet_prefix_length (number): CIDR prefix length for each subnet (e.g., 24).
    Must be between the VPC prefix length and /28.
  - enable_dns_hostnames (bool): Whether to enable DNS hostnames in the VPC.
  - enable_dns_support (bool): Whether to enable DNS support in the VPC. Must be
    true if `enable_dns_hostnames` is true.

Notes:
  - Ensure `vpc_cidr` provides enough address space for the requested number of
    subnets at the chosen `subnet_prefix_length`.
  - Subnet counts are interpreted as logical counts; the module will spread
    subnets across AZs where possible.

Example:
  networking = {
    vpc_cidr             = "10.0.0.0/16"
    public_subnet_count  = 2
    private_subnet_count = 2
    subnet_prefix_length = 24
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
EOF
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


variable "ec2_settings" {
  description = <<EOF
Object containing EC2/ASG settings for this module.

Attributes:
  - ami_id (string): AMI ID to use for EC2 instances; set to empty string to auto-select latest Ubuntu 22.04.
  - min_size (number): ASG minimum size.
  - max_size (number): ASG maximum size.
  - desired_capacity (number): ASG desired capacity.
  - health_check_grace_period (number): ASG health check grace period in seconds.

Example:
  ec2_settings = {
    ami_id                    = "" # leave empty to auto-select
    min_size                  = 1
    max_size                  = 4
    desired_capacity          = 1
    health_check_grace_period = 240
  }
EOF
  type = object({
    ami_id                    = string
    min_size                  = number
    max_size                  = number
    desired_capacity          = number
    health_check_grace_period = number
  })

  default = {
    ami_id                    = ""
    min_size                  = 1
    max_size                  = 4
    desired_capacity          = 1
    health_check_grace_period = 240
  }
}