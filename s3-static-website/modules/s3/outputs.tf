output "bucket_id" {
  description = "The ID (name) of the created S3 bucket"
  value       = aws_s3_bucket.website_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket"
  value       = aws_s3_bucket.website_bucket.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the created S3 bucket"
  value       = aws_s3_bucket.website_bucket.bucket_regional_domain_name
}

output "cloudfront_logs_bucket_id" {
  description = "The ID (name) of the CloudFront logs bucket (if created)"
  value       = var.enable_logging ? aws_s3_bucket.cloudfront_logs_bucket[0].id : ""
}

output "cloudfront_logs_bucket_arn" {
  description = "The ARN of the CloudFront logs bucket (if created)"
  value       = var.enable_logging ? aws_s3_bucket.cloudfront_logs_bucket[0].arn : ""
}
