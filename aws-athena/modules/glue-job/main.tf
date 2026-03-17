/*
Glue Job Module - ETL Processing

This module creates AWS Glue ETL resources for transforming data:
- Glue ETL Job: PySpark job that reads data from Glue Catalog, transforms
  to desired format (Parquet recommended for Athena), and writes to S3
- The job uses job bookmarks for incremental processing
- Supports configurable worker types, timeouts, and retry policies
*/

# Glue ETL Job
resource "aws_glue_job" "etl_job" {
  name     = "${var.project_name}-etl-job"
  role_arn = var.glue_service_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket_name}/${var.glue_job_config.script_path}"
    python_version  = var.glue_job_config.job_language == "python" ? var.glue_job_config.python_version : null
  }

  default_arguments = {
    "--enable-spark-ui"         = tostring(var.glue_job_config.enable_spark_ui)
    "--enable-job-insights"     = tostring(var.glue_job_config.enable_job_insights)
    "--spark-event-logs-path"   = "s3://${var.processed_data_bucket_name}/spark-logs/"
    "--enable-glue-datacatalog" = "true"
    "--TempDir"                 = "s3://${var.processed_data_bucket_name}/temp/"
    "--job-language"            = var.glue_job_config.job_language
    "--input_database"          = var.input_database
    "--input_table_prefix"      = var.glue_job_config.input_table_prefix
    "--output_bucket"           = var.processed_data_bucket_name
    "--output_path"             = var.glue_job_config.output_path
    "--output_format"           = var.glue_job_config.output_format
    "--enable_quality_checks"   = tostring(var.glue_job_config.enable_quality_checks)
    "--quality_report_path"     = var.glue_job_config.quality_report_path
    "--bad_data_path"           = var.glue_job_config.bad_data_path
    "--filter_bad_data"         = tostring(var.glue_job_config.filter_bad_data)
    "--enable_partitioning"     = tostring(var.glue_job_config.enable_partitioning)
    "--partition_columns"       = var.glue_job_config.partition_columns
    "--job-bookmark"            = var.glue_job_config.job_bookmark_option
  }

  worker_type       = var.glue_job_config.worker_type
  number_of_workers = var.glue_job_config.number_of_workers
  glue_version      = var.glue_job_config.version
  timeout           = var.glue_job_config.job_timeout
  max_retries       = var.glue_job_config.max_retries

  execution_property {
    max_concurrent_runs = var.glue_job_config.max_concurrent_runs
  }

  tags = {
    Name = "${var.project_name}-etl-job"
  }
}
