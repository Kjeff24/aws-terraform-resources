############################
# S3 Module
############################
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
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

  depends_on = [module.iam]
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
