############################
# 🌍 General Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}
