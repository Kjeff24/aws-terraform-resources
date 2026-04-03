variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption for S3 buckets"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for S3 bucket encryption. If null, uses AWS-managed encryption."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow deletion of non-empty S3 buckets. Set to true only for non-production environments."
  type        = bool
  default     = false
}
