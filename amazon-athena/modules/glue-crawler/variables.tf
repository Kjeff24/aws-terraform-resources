variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "catalog_database_name" {
  description = "Name of the Glue Catalog database"
  type        = string
}

variable "raw_data_bucket_name" {
  description = "Name of the S3 bucket containing raw data"
  type        = string
  default     = null
}

variable "processed_data_bucket_name" {
  description = "Name of the S3 bucket containing processed data"
  type        = string
  default     = null
}

variable "crawler_type" {
  description = "Type of crawler: 'raw' for raw data, 'processed' for processed data"
  type        = string
  default     = "raw"
  validation {
    condition     = contains(["raw", "processed"], var.crawler_type)
    error_message = "crawler_type must be either 'raw' or 'processed'."
  }
}

variable "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue service"
  type        = string
}

variable "table_prefix" {
  description = "Prefix for table names created by the crawler"
  type        = string
  default     = "raw_"
}

variable "crawler_schedule" {
  description = "Schedule expression for the crawler (cron or rate). Use null for manual runs."
  type        = string
  default     = null
}
