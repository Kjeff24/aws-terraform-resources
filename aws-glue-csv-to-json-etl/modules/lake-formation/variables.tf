variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "raw_data_bucket_arn" {
  description = "ARN of the raw data S3 bucket"
  type        = string
}

variable "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue service"
  type        = string
}

variable "catalog_database_name" {
  description = "Name of the Glue Catalog database"
  type        = string
}
