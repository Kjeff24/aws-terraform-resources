################################################################################
# AWS Glue CSV to JSON ETL Pipeline - Main Configuration
################################################################################
# This file orchestrates the complete AWS Glue ETL pipeline infrastructure:
# - S3 buckets for raw CSV data and processed JSON output
# - IAM roles and policies for Glue service access
# - Glue Crawler to discover and catalog CSV files
# - Glue ETL Job to transform CSV data to JSON format
# - Optional Lake Formation integration for fine-grained access control
# - Glue Workflow to automate the ETL process (Crawler → Job)
################################################################################

############################
# S3 Module
############################
module "s3" {
  source = "./modules/s3"

  project_name     = var.project_name
  enable_versioning = var.enable_versioning
}


############################
# IAM Module
############################
module "iam" {
  source = "./modules/iam"

  project_name               = var.project_name
  region                     = var.region
  raw_data_bucket_arn        = module.s3.raw_data_bucket_arn
  processed_data_bucket_arn  = module.s3.processed_data_bucket_arn
  log_retention_days         = var.glue_job.log_retention_days
  enable_lake_formation      = var.enable_lake_formation

  depends_on = [module.s3]
}

############################
# Glue Crawler Module
############################
module "glue_crawler" {
  source = "./modules/glue-crawler"

  project_name            = var.project_name
  region                  = var.region
  raw_data_bucket_name    = module.s3.raw_data_bucket_name
  glue_service_role_arn   = module.iam.glue_service_role_arn
  crawler_schedule        = var.crawler_schedule
  enable_lake_formation   = var.enable_lake_formation

  depends_on = [module.iam]
}

############################
# Lake Formation Module (Conditional)
############################
module "lake_formation" {
  count  = var.enable_lake_formation ? 1 : 0
  source = "./modules/lake-formation"

  project_name           = var.project_name
  raw_data_bucket_arn    = module.s3.raw_data_bucket_arn
  glue_service_role_arn  = module.iam.glue_service_role_arn
  catalog_database_name  = module.glue_crawler.catalog_database_name

  depends_on = [module.glue_crawler, module.iam]
}

############################
# Glue Job Module
############################
module "glue_job" {
  source = "./modules/glue-job"

  project_name               = var.project_name
  glue_service_role_arn      = module.iam.glue_service_role_arn
  scripts_bucket_name        = module.s3.processed_data_bucket_name
  glue_script_path           = var.glue_job.script_path
  processed_data_bucket_name = module.s3.processed_data_bucket_name
  input_database             = module.glue_crawler.catalog_database_name
  input_table_prefix         = var.glue_job.input_table_prefix
  output_path                = var.glue_job.output_path
  crawler_name               = module.glue_crawler.crawler_name
  worker_type                = var.glue_job.worker_type
  number_of_workers          = var.glue_job.number_of_workers
  glue_version               = var.glue_job.version
  job_timeout                = var.glue_job.job_timeout
  max_retries                = var.glue_job.max_retries
  max_concurrent_runs        = var.glue_job.max_concurrent_runs

  depends_on = [module.glue_crawler]
}
