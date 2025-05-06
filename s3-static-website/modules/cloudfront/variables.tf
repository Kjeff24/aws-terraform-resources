variable "region" {
  description = "AWS region for the S3 bucket (CloudFront is global)."
  type        = string
}

variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "s3_origin_id" {
  description = "The ID of the S3 bucket to use as the origin"
  type        = string
}

variable "s3_bucket_domain" {
  description = "The S3 bucket's regional domain name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  type        = string
}

variable "cloudfront_aliases" {
  description = "List of CNAMEs for the distribution"
  type        = list(string)
  default     = []
}

variable "default_root_object" {
  description = "The default root object for the CloudFront distribution"
  type        = string
}

variable "cloudfront_price_class" {
  description = "The price class for the CloudFront distribution"
  type        = string
  
}

variable "enable_logging" {
  description = "Whether CloudFront access logging should be enabled"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "Name of the S3 bucket to receive CloudFront access logs (bucket name, not domain). If provided, CloudFront logging will be configured when enable_logging = true. The module will append `.s3.amazonaws.com` to build the logging target." 
  type        = string
  default     = ""
}

variable "logging_prefix" {
  description = "Optional prefix for log files in the logging bucket"
  type        = string
  default     = "cloudfront/"
}

variable "logging_include_cookies" {
  description = "Whether CloudFront should include cookies in the access logs"
  type        = bool
  default     = false
}

