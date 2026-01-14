############################
# 🌐 General Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "region must be a valid AWS region identifier (e.g., eu-west-1)."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "aws-glue-csv-to-json-etl"

  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.project_name)) &&
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 20
    )
    error_message = "project_name must be 3-20 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "AWS Glue CSV to JSON ETL"
  }
}

############################
# 🔄 AWS Glue Configuration (object)
############################
variable "glue_job" {
  description = "Grouped configuration for AWS Glue job and logging"
  type = object({
    script_path          = string
    input_table_prefix   = string
    output_path          = string
    worker_type          = string
    number_of_workers    = number
    version              = string
    job_timeout          = number
    max_retries          = number
    max_concurrent_runs  = number
    log_retention_days   = number
  })
  default = {
    script_path          = "scripts/csv-to-json.py"
    input_table_prefix   = "raw_"
    output_path          = "output/"
    worker_type          = "G.1X"
    number_of_workers    = 2
    version              = "5.0"
    job_timeout          = 2880
    max_retries          = 1
    max_concurrent_runs  = 1
    log_retention_days   = 1
  }
}

############################
# 🗓️ Glue Crawler Schedule (separate)
############################
variable "crawler_schedule" {
  description = "Schedule expression for the Glue crawler (e.g., cron or rate). Use null for manual runs."
  type        = string
  default     = null
}
