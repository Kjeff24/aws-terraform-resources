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
# 🧩 EC2 Instance settings
############################
variable "instance_config" {
  description = "Configuration for the EC2 instance module"
  type = object({
    ami_id                 : string
    instance_type          : string
    subnet_id              : string
    key_name               : string
    associate_public_ip    : bool
    iam_instance_profile   : string
    disable_api_termination: bool
  })

  default = {
    ami_id                 = "ami-0f9fa7cd5a3697470" # Leave empty to auto-select latest Ubuntu 22.04 for the region
    instance_type          = "t2.micro"
    subnet_id              = ""                     # can leave empty if using default VPC
    key_name               = ""        # can leave empty to use generated key
    associate_public_ip    = true
    iam_instance_profile   = ""                    # No IAM role by default
    disable_api_termination = false
  }

  # ✅ Field-level validations for instance_config
  validation {
    condition     = var.instance_config.ami_id == "" || can(regex("^ami-[0-9a-f]+$", var.instance_config.ami_id))
    error_message = "instance_config.ami_id must be empty or a valid AMI id (e.g., ami-123abc456def78901)."
  }

  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_config.instance_type))
    error_message = "instance_config.instance_type must be in the form family.size (e.g., t3.micro)."
  }

  validation {
    condition     = var.instance_config.subnet_id == "" || can(regex("^subnet-[0-9a-f]+$", var.instance_config.subnet_id))
    error_message = "instance_config.subnet_id must be empty or a valid subnet id (e.g., subnet-abc123...)."
  }

  validation {
    condition     = var.instance_config.key_name == "" || can(regex("^[A-Za-z0-9._-]{1,255}$", var.instance_config.key_name))
    error_message = "instance_config.key_name must be empty or contain only letters, numbers, dot, underscore, and hyphen (max 255 chars)."
  }

  validation {
    # Accept either a simple name or a full instance profile ARN
    condition     = var.instance_config.iam_instance_profile == "" || can(regex("^[A-Za-z0-9+=,.@_-]{1,128}$", var.instance_config.iam_instance_profile)) || can(regex("^arn:aws:iam::[0-9]{12}:instance-profile/[A-Za-z0-9+=,.@_-]{1,128}$", var.instance_config.iam_instance_profile))
    error_message = "instance_config.iam_instance_profile must be empty, an instance profile name, or a valid instance profile ARN."
  }
}

