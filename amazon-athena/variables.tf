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
  default     = "athena-analytics"

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
    Project     = "AWS Athena Analytics"
  }
}

############################
# 📦 S3 Configuration
############################
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

############################
# 🗄️ Glue Data Catalog Configuration
############################
variable "glue_database" {
  description = "Glue Data Catalog database configuration"
  type = object({
    name        = string
    description = string
  })
  default = {
    name        = "athena_database"
    description = "Database for Athena queries"
  }
}

variable "glue_tables" {
  description = "Map of Glue tables to create. Key is table name, value contains table configuration."
  type = map(object({
    description   = optional(string, "")
    location      = string
    input_format  = optional(string, "org.apache.hadoop.mapred.TextInputFormat")
    output_format = optional(string, "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat")
    serde_library = optional(string, "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe")
    columns = list(object({
      name = string
      type = string
    }))
    partition_keys = optional(list(object({
      name = string
      type = string
    })), [])
  }))
  default = {}
}

############################
# 🔍 Athena Workgroup Configuration
############################
variable "athena_workgroups" {
  description = "Map of Athena workgroups to create"
  type = map(object({
    description                = optional(string, "")
    enforce_workgroup_config   = optional(bool, false)
    publish_cloudwatch_metrics = optional(bool, true)
    result_configuration = object({
      output_location = optional(string, null)
      encryption_configuration = optional(object({
        encryption_option = string
        kms_key           = optional(string, null)
      }), null)
    })
    engine_version = optional(object({
      selected_engine_version = optional(string, "Athena engine version 3")
    }), null)
    state = optional(string, "ENABLED")
  }))
  default = {
    primary = {
      description                = "Primary Athena workgroup"
      enforce_workgroup_config   = false
      publish_cloudwatch_metrics = true
      result_configuration = {
        output_location = null
        encryption_configuration = {
          encryption_option = "SSE_S3"
          kms_key           = null
        }
      }
      state = "ENABLED"
    }
  }
}

############################
# 🔄 Glue ETL Configuration
############################
variable "enable_glue_etl" {
  description = "Enable Glue ETL pipeline (crawler, job, workflow)"
  type        = bool
  default     = true
}

variable "glue_crawler" {
  description = "Glue Crawler configuration"
  type = object({
    table_prefix = optional(string, "raw_")
    schedule     = optional(string, null)
  })
  default = {
    table_prefix = "raw_"
    schedule     = null
  }
}

variable "glue_job_config" {
  description = "Configuration for the Glue ETL job"
  type = object({
    script_path           = string
    input_table_prefix    = string
    output_path           = string
    output_format         = string
    worker_type           = string
    number_of_workers     = number
    version               = string
    job_timeout           = number
    max_retries           = number
    max_concurrent_runs   = number
    enable_quality_checks = bool
    quality_report_path   = string
    bad_data_path         = string
    filter_bad_data       = bool
    job_bookmark_option   = string
    enable_partitioning   = bool
    partition_columns     = string
    enable_job_insights   = bool
    enable_spark_ui       = bool
    job_language          = string
    python_version        = string
    log_retention_days    = number
  })
  default = {
    script_path           = "scripts/glue-etl-job.py"
    input_table_prefix    = "raw_"
    output_path           = "processed/"
    output_format         = "parquet" # Parquet is recommended for Athena
    worker_type           = "G.1X"
    number_of_workers     = 2
    version               = "5.0"
    job_timeout           = 2880
    max_retries           = 1
    max_concurrent_runs   = 1
    enable_quality_checks = true
    quality_report_path   = "quality-reports/"
    bad_data_path         = "bad-data/"
    filter_bad_data       = true
    job_bookmark_option   = "job-bookmark-disable"
    enable_partitioning   = true
    partition_columns     = "year,month,day"
    enable_job_insights   = true
    enable_spark_ui       = true
    job_language          = "python"
    python_version        = "3"
    log_retention_days    = 1
  }
  validation {
    condition     = contains(["json", "parquet", "csv", "orc"], lower(var.glue_job_config.output_format))
    error_message = "output_format must be one of: json, parquet, csv, orc (case-insensitive). Parquet is recommended for Athena."
  }
}
