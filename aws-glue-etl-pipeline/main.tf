/*
AWS Glue CSV to JSON ETL Pipeline - Main Configuration

This file orchestrates the complete AWS Glue ETL pipeline infrastructure:
- S3 buckets for raw CSV data and processed JSON output
- IAM roles and policies for Glue service access
- Glue Crawler to discover and catalog CSV files
- Glue ETL Job to transform CSV data to JSON format
- Optional Lake Formation integration for fine-grained access control
- Glue Workflow to automate the ETL process (Crawler → Job)
*/

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name     = var.project_name
  enable_versioning = var.enable_versioning
}


# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name               = var.project_name
  region                     = var.region
  raw_data_bucket_arn        = module.s3.raw_data_bucket_arn
  processed_data_bucket_arn  = module.s3.processed_data_bucket_arn
  log_retention_days         = var.glue_job.log_retention_days
  enable_lake_formation      = var.lake_formation.enable

  depends_on = [module.s3]
}

# Glue Database Module - Created first (needed by both Lake Formation and Crawler)
module "glue_database" {
  source = "./modules/glue-database"

  project_name = var.project_name

  depends_on = [module.iam]
}

# Lake Formation Module (Conditional) - Must be created BEFORE crawler when LF is enabled
module "lake_formation" {
  count  = var.lake_formation.enable ? 1 : 0
  source = "./modules/lake-formation"

  project_name          = var.project_name
  raw_data_bucket_arn   = module.s3.raw_data_bucket_arn
  glue_service_role_arn = module.iam.glue_service_role_arn
  catalog_database_name = module.glue_database.database_name
  database_permissions  = var.lake_formation.database_permissions

  depends_on = [module.iam, module.glue_database]
}

# Glue Crawler Module - With Lake Formation (when enabled)
module "glue_crawler" {
  count  = var.lake_formation.enable ? 1 : 0
  source = "./modules/glue-crawler"

  project_name            = var.project_name
  region                  = var.region
  raw_data_bucket_name    = module.s3.raw_data_bucket_name
  glue_service_role_arn   = module.iam.glue_service_role_arn
  crawler_schedule        = var.crawler_schedule
  enable_lake_formation   = var.lake_formation.enable
  catalog_database_name   = module.glue_database.database_name

  depends_on = [
    module.iam,
    module.glue_database,
    module.lake_formation[0]
  ]
}

# Glue Crawler Module - Without Lake Formation (when disabled)
module "glue_crawler_no_lf" {
  count  = var.lake_formation.enable ? 0 : 1
  source = "./modules/glue-crawler"

  project_name            = var.project_name
  region                  = var.region
  raw_data_bucket_name    = module.s3.raw_data_bucket_name
  glue_service_role_arn   = module.iam.glue_service_role_arn
  crawler_schedule        = var.crawler_schedule
  enable_lake_formation   = var.lake_formation.enable
  catalog_database_name   = module.glue_database.database_name

  depends_on = [
    module.iam,
    module.glue_database
  ]
}

# Local to get the active crawler module
locals {
  crawler_module = var.lake_formation.enable ? module.glue_crawler[0] : module.glue_crawler_no_lf[0]
}

# Glue Job Module
module "glue_job" {
  source = "./modules/glue-job"

  project_name               = var.project_name
  glue_service_role_arn      = module.iam.glue_service_role_arn
  scripts_bucket_name        = module.s3.processed_data_bucket_name
  processed_data_bucket_name = module.s3.processed_data_bucket_name
  input_database             = local.crawler_module.catalog_database_name
  crawler_name               = local.crawler_module.crawler_name
  glue_job_config            = var.glue_job

  depends_on = [local.crawler_module]
}
