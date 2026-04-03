output "raw_data_bucket_name" {
  description = "Name of the S3 bucket for raw data (input for Glue ETL)"
  value       = aws_s3_bucket.raw_data_bucket.id
}

output "raw_data_bucket_arn" {
  description = "ARN of the S3 bucket for raw data"
  value       = aws_s3_bucket.raw_data_bucket.arn
}

output "processed_data_bucket_name" {
  description = "Name of the S3 bucket for processed data (output from Glue ETL, input for Athena)"
  value       = aws_s3_bucket.processed_data_bucket.id
}

output "processed_data_bucket_arn" {
  description = "ARN of the S3 bucket for processed data"
  value       = aws_s3_bucket.processed_data_bucket.arn
}

# Legacy outputs for backward compatibility
output "data_bucket_name" {
  description = "Name of the processed data bucket (for backward compatibility)"
  value       = aws_s3_bucket.processed_data_bucket.id
}

output "data_bucket_arn" {
  description = "ARN of the processed data bucket (for backward compatibility)"
  value       = aws_s3_bucket.processed_data_bucket.arn
}

output "query_results_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.query_results_bucket.id
}

output "query_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.query_results_bucket.arn
}
