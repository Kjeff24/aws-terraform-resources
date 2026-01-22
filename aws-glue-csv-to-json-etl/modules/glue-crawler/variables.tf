variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "raw_data_bucket_name" {
  description = "Name of the raw data S3 bucket"
  type        = string
}

variable "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue service"
  type        = string
}

variable "crawler_schedule" {
  description = "Schedule expression for the crawler (e.g., 'cron(0 2 * * ? *)' for daily at 2 AM, or null for manual)"
  type        = string
}

variable "enable_lake_formation" {
  description = "Enable Lake Formation integration for the crawler"
  type        = bool
}

variable "catalog_database_name" {
  description = "Name of the Glue Catalog database (must already exist)"
  type        = string
}
