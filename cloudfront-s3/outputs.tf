
output "cloudfront_domain_name" {
	description = "CloudFront distribution domain name"
	value       = module.cloudfront.domain_name
}
