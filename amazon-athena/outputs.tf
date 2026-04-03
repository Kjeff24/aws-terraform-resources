############################
# S3 Outputs
############################
output "raw_data_bucket_name" {
  description = "Name of the S3 bucket for raw data (input for Glue ETL)"
  value       = module.s3.raw_data_bucket_name
}

output "raw_data_bucket_arn" {
  description = "ARN of the S3 bucket for raw data"
  value       = module.s3.raw_data_bucket_arn
}

output "processed_data_bucket_name" {
  description = "Name of the S3 bucket for processed data (output from Glue ETL, input for Athena)"
  value       = module.s3.processed_data_bucket_name
}

output "processed_data_bucket_arn" {
  description = "ARN of the S3 bucket for processed data"
  value       = module.s3.processed_data_bucket_arn
}

# Legacy outputs for backward compatibility
output "data_bucket_name" {
  description = "Name of the processed data bucket (for backward compatibility)"
  value       = module.s3.processed_data_bucket_name
}

output "data_bucket_arn" {
  description = "ARN of the processed data bucket (for backward compatibility)"
  value       = module.s3.processed_data_bucket_arn
}

output "query_results_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  value       = module.s3.query_results_bucket_name
}

output "query_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena query results"
  value       = module.s3.query_results_bucket_arn
}

############################
# Glue Data Catalog Outputs
############################
output "glue_database_name" {
  description = "Name of the Glue Data Catalog database"
  value       = module.glue_catalog.database_name
}

output "glue_database_arn" {
  description = "ARN of the Glue Data Catalog database"
  value       = module.glue_catalog.database_arn
}

output "glue_table_names" {
  description = "List of created Glue table names"
  value       = module.glue_catalog.table_names
}

############################
# Athena Workgroup Outputs
############################
output "athena_workgroup_names" {
  description = "Map of Athena workgroup names (key: workgroup key, value: workgroup name)"
  value       = module.athena.workgroup_names
}

output "athena_workgroup_arns" {
  description = "Map of Athena workgroup ARNs (key: workgroup key, value: workgroup ARN)"
  value       = module.athena.workgroup_arns
}

############################
# Glue ETL Outputs
############################
output "glue_raw_crawler_name" {
  description = "Name of the Glue crawler for raw data (if Glue ETL is enabled)"
  value       = try(module.glue_crawler_raw[0].crawler_name, null)
}

output "glue_processed_crawler_name" {
  description = "Name of the Glue crawler for processed data (if Glue ETL is enabled)"
  value       = try(module.glue_crawler_processed[0].crawler_name, null)
}

output "glue_job_name" {
  description = "Name of the Glue ETL job (if Glue ETL is enabled)"
  value       = try(module.glue_job[0].job_name, null)
}

output "glue_workflow_name" {
  description = "Name of the Glue workflow (if Glue ETL is enabled)"
  value       = try(module.glue_workflow[0].workflow_name, null)
}

output "glue_raw_database_name" {
  description = "Name of the Glue database for raw data"
  value       = module.glue_database_raw.database_name
}

############################
# IAM Outputs
############################
output "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue service"
  value       = module.iam.glue_service_role_arn
}

output "athena_user_role_arn" {
  description = "ARN of the IAM role for Athena queries"
  value       = module.iam.athena_user_role_arn
}

output "athena_user_role_name" {
  description = "Name of the IAM role for Athena queries"
  value       = module.iam.athena_user_role_name
}
