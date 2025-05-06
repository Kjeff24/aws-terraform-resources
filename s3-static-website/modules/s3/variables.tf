variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}


variable "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  type        = string
}

variable "enable_logging" {
  description = "Whether to create a logs bucket for CloudFront access logs"
  type        = bool
}

