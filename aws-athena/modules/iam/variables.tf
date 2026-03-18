variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "raw_data_bucket_arn" {
  description = "ARN of the S3 raw data bucket"
  type        = string
}

variable "processed_data_bucket_arn" {
  description = "ARN of the S3 processed data bucket"
  type        = string
}

variable "query_results_bucket_arn" {
  description = "ARN of the S3 query results bucket"
  type        = string
}

variable "glue_raw_database_name" {
  description = "Name of the Glue raw data catalog database"
  type        = string
}

variable "glue_catalog_database_name" {
  description = "Name of the Glue processed/catalog database used by Athena"
  type        = string
}

# Note: Athena user role is always created with default naming

variable "log_retention_days" {
  description = "CloudWatch log retention in days for Glue logs"
  type        = number
  default     = 7
}
