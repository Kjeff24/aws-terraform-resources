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

variable "glue_script_path" {
  description = "Path to the Glue ETL script in S3 (relative to bucket root)"
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

variable "input_table_prefix" {
  description = "Prefix for input table names (e.g., 'raw_')"
  type        = string
}

variable "output_path" {
  description = "Output path in S3 for processed files (relative to bucket)"
  type        = string
}

variable "output_format" {
  description = "Output file format: json, parquet, csv, orc"
  type        = string
}

variable "crawler_name" {
  description = "Name of the Glue crawler that triggers the job"
  type        = string
}

variable "worker_type" {
  description = "Worker type for the Glue job (G.1X, G.2X, Z.2X)"
  type        = string
}

variable "number_of_workers" {
  description = "Number of workers for the Glue job"
  type        = number
}

variable "glue_version" {
  description = "Version of AWS Glue to use"
  type        = string
}

variable "job_timeout" {
  description = "Job timeout in minutes"
  type        = number
}

variable "max_retries" {
  description = "Maximum number of job retries on failure"
  type        = number
}

variable "max_concurrent_runs" {
  description = "Maximum number of concurrent runs of the job"
  type        = number
}
