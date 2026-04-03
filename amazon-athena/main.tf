/*
AWS Athena Analytics with Glue ETL - Main Configuration

This file orchestrates the complete integrated data pipeline:
- S3 buckets for raw data, processed data, and query results
- Glue Data Catalog for metadata management
- Glue Crawler for automatic schema discovery
- Glue ETL Job for data transformation
- Glue Workflow for pipeline orchestration
- Athena workgroups for SQL queries
- IAM roles and policies for secure access

Pipeline Flow:
1. Raw data uploaded to S3 raw data bucket
2. Glue Crawler (raw) discovers and catalogs raw data
3. Glue ETL Job transforms data to optimized format (Parquet)
4. Processed data stored in processed data bucket
5. Glue Crawler (processed) automatically discovers and catalogs processed data
6. Athena queries processed data using automatically discovered tables
*/

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name      = var.project_name
  enable_versioning = var.enable_versioning
  enable_encryption = var.enable_encryption
  kms_key_id        = var.kms_key_id
  force_destroy     = var.force_destroy
}

# IAM Module (for both Glue and Athena)
module "iam" {
  source = "./modules/iam"

  project_name               = var.project_name
  region                     = var.region
  raw_data_bucket_arn        = module.s3.raw_data_bucket_arn
  processed_data_bucket_arn  = module.s3.processed_data_bucket_arn
  query_results_bucket_arn   = module.s3.query_results_bucket_arn
  log_retention_days         = var.glue_job_config.log_retention_days
  glue_raw_database_name     = module.glue_database_raw.database_name
  glue_catalog_database_name = module.glue_catalog.database_name

  depends_on = [module.s3, module.glue_database_raw, module.glue_catalog]
}

# Glue Database Module (for raw data)
module "glue_database_raw" {
  source = "./modules/glue-database"

  project_name = var.project_name
  description  = "Glue Catalog database for raw data"
}

# Glue Crawler Module (for raw data)
module "glue_crawler_raw" {
  count  = var.enable_glue_etl ? 1 : 0
  source = "./modules/glue-crawler"

  project_name          = var.project_name
  catalog_database_name = module.glue_database_raw.database_name
  raw_data_bucket_name  = module.s3.raw_data_bucket_name
  glue_service_role_arn = module.iam.glue_service_role_arn
  table_prefix          = var.glue_crawler.table_prefix
  crawler_schedule      = var.glue_crawler.schedule
  crawler_type          = "raw"

  depends_on = [module.iam, module.glue_database_raw]
}

# Glue Crawler Module (for processed data - automatically discovers tables for Athena)
module "glue_crawler_processed" {
  count  = var.enable_glue_etl ? 1 : 0
  source = "./modules/glue-crawler"

  project_name               = var.project_name
  catalog_database_name      = module.glue_catalog.database_name
  processed_data_bucket_name = module.s3.processed_data_bucket_name
  glue_service_role_arn      = module.iam.glue_service_role_arn
  table_prefix               = ""   # No prefix for processed tables
  crawler_schedule           = null # Run on-demand after ETL job
  crawler_type               = "processed"

  depends_on = [module.iam, module.glue_catalog]
}

# Glue Job Module
module "glue_job" {
  count  = var.enable_glue_etl ? 1 : 0
  source = "./modules/glue-job"

  project_name               = var.project_name
  glue_service_role_arn      = module.iam.glue_service_role_arn
  scripts_bucket_name        = module.s3.processed_data_bucket_name
  processed_data_bucket_name = module.s3.processed_data_bucket_name
  input_database             = module.glue_database_raw.database_name
  glue_job_config            = var.glue_job_config

  depends_on = [module.iam, module.glue_database_raw]
}

# Glue Workflow Module
module "glue_workflow" {
  count  = var.enable_glue_etl ? 1 : 0
  source = "./modules/glue-workflow"

  project_name           = var.project_name
  raw_crawler_name       = module.glue_crawler_raw[0].crawler_name
  job_name               = module.glue_job[0].job_name
  processed_crawler_name = module.glue_crawler_processed[0].crawler_name

  depends_on = [module.glue_crawler_raw, module.glue_job, module.glue_crawler_processed]
}

# Glue Data Catalog Module (for processed data - used by Athena)
module "glue_catalog" {
  source = "./modules/glue-catalog"

  project_name         = var.project_name
  database_name        = var.glue_database.name
  database_description = var.glue_database.description
  tables               = var.glue_tables

  depends_on = [module.s3]
}

# Athena Workgroup Module
module "athena" {
  source = "./modules/athena"

  project_name         = var.project_name
  workgroups           = var.athena_workgroups
  query_results_bucket = module.s3.query_results_bucket_name

  depends_on = [module.s3]
}
