output "raw_data_bucket_name" {
  description = "Name of the S3 bucket for raw CSV data"
  value       = aws_s3_bucket.raw_data_bucket.id
}

output "raw_data_bucket_arn" {
  description = "ARN of the S3 bucket for raw CSV data"
  value       = aws_s3_bucket.raw_data_bucket.arn
}

output "processed_data_bucket_name" {
  description = "Name of the S3 bucket for processed JSON data"
  value       = aws_s3_bucket.processed_data_bucket.id
}

output "processed_data_bucket_arn" {
  description = "ARN of the S3 bucket for processed JSON data"
  value       = aws_s3_bucket.processed_data_bucket.arn
}
