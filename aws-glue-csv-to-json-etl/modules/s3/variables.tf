variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
}
