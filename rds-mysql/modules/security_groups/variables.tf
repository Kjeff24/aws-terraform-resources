variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "my-site"
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "vpc_cidr" {
    description = "CIDR block of the VPC for ingress rules"
    type        = string
}