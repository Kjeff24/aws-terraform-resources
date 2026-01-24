variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue service"
  type        = string
}

variable "scripts_bucket_name" {
  description = "Name of the S3 bucket containing Glue scripts"
  type        = string
}

variable "processed_data_bucket_name" {
  description = "Name of the S3 bucket for processed data output"
  type        = string
}

variable "input_database" {
  description = "Glue Catalog database name containing input tables"
  type        = string
}

variable "crawler_name" {
  description = "Name of the Glue crawler that triggers the job"
  type        = string
}

variable "glue_job_config" {
  description = "Configuration for the Glue ETL job"
  type = object({
    script_path            = string
    input_table_prefix     = string
    output_path            = string
    output_format          = string
    worker_type            = string
    number_of_workers      = number
    version                = string
    job_timeout            = number
    max_retries            = number
    max_concurrent_runs    = number
    enable_quality_checks  = bool
    quality_report_path    = string
    bad_data_path          = string
    filter_bad_data        = bool
    job_bookmark_option    = string
    enable_partitioning    = bool
    partition_columns      = string
  })
}
