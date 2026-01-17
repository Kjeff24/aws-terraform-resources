############################
# Glue ETL Job
############################
resource "aws_glue_job" "csv_to_json" {
  name              = "${var.project_name}-csv-to-json"
  role_arn          = var.glue_service_role_arn
  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket_name}/${var.glue_script_path}"
    python_version  = "3"
  }

  default_arguments = {
    "--job-bookmark-option"      = "job-bookmark-enable"
    "--enable-spark-ui"          = "true"
    "--spark-event-logs-path"    = "s3://${var.processed_data_bucket_name}/spark-logs/"
    "--enable-glue-datacatalog"  = "true"
    "--TempDir"                  = "s3://${var.processed_data_bucket_name}/temp/"
    "--job-language"             = "python"
    "--input_database"           = var.input_database
    "--input_table_prefix"       = var.input_table_prefix
    "--output_bucket"            = var.processed_data_bucket_name
    "--output_path"              = var.output_path
  }

  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  glue_version      = var.glue_version
  timeout           = var.job_timeout
  max_retries       = var.max_retries

  execution_property {
    max_concurrent_runs = var.max_concurrent_runs
  }

  tags = {
    Name = "${var.project_name}-csv-to-json"
  }
}

############################
# Glue Workflow
############################
resource "aws_glue_workflow" "csv_to_json_workflow" {
  name        = "${var.project_name}-workflow"
  description = "Automated ETL workflow: Crawl CSV → Transform to JSON"

  tags = {
    Name = "${var.project_name}-workflow"
  }
}

############################
# Workflow Trigger for Crawler
############################
resource "aws_glue_trigger" "crawler_trigger" {
  name          = "${var.project_name}-start-crawler"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.csv_to_json_workflow.name

  actions {
    crawler_name = var.crawler_name
  }
}

############################
# Workflow Trigger for ETL Job
############################
resource "aws_glue_trigger" "job_trigger" {
  name            = "${var.project_name}-start-job"
  type            = "CONDITIONAL"
  workflow_name   = aws_glue_workflow.csv_to_json_workflow.name
  predicate {
    conditions {
      crawler_name = var.crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.csv_to_json.name
  }

  depends_on = [aws_glue_trigger.crawler_trigger]
}
