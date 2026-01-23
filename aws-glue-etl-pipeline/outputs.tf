############################
# S3 Outputs
############################
output "raw_data_bucket_name" {
  description = "Name of the S3 bucket for raw CSV data"
  value       = module.s3.raw_data_bucket_name
}

output "raw_data_bucket_arn" {
  description = "ARN of the S3 bucket for raw CSV data"
  value       = module.s3.raw_data_bucket_arn
}

output "processed_data_bucket_name" {
  description = "Name of the S3 bucket for processed JSON data"
  value       = module.s3.processed_data_bucket_name
}

output "processed_data_bucket_arn" {
  description = "ARN of the S3 bucket for processed JSON data"
  value       = module.s3.processed_data_bucket_arn
}

############################
# Glue Crawler Outputs
############################
output "glue_crawler_name" {
  description = "Name of the Glue crawler"
  value       = var.lake_formation.enable ? module.glue_crawler[0].crawler_name : module.glue_crawler_no_lf[0].crawler_name
}

output "glue_crawler_arn" {
  description = "ARN of the Glue crawler"
  value       = var.lake_formation.enable ? module.glue_crawler[0].crawler_arn : module.glue_crawler_no_lf[0].crawler_arn
}

output "glue_catalog_database_name" {
  description = "Name of the Glue Catalog database"
  value       = module.glue_database.database_name
}

############################
# Glue Job Outputs
############################
output "glue_job_name" {
  description = "Name of the Glue ETL job"
  value       = module.glue_job.job_name
}

output "glue_job_arn" {
  description = "ARN of the Glue ETL job"
  value       = module.glue_job.job_arn
}

############################
# Glue Workflow Outputs
############################
output "glue_workflow_name" {
  description = "Name of the Glue workflow"
  value       = module.glue_job.workflow_name
}

output "glue_workflow_arn" {
  description = "ARN of the Glue workflow"
  value       = module.glue_job.workflow_arn
}

############################
# IAM Outputs
############################
output "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue service"
  value       = module.iam.glue_service_role_arn
}

output "glue_logs_group_name" {
  description = "CloudWatch log group name for Glue"
  value       = module.iam.glue_logs_group_name
}
