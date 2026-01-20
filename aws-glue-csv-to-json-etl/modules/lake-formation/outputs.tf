output "resource_arn" {
  description = "ARN of the registered Lake Formation resource"
  value       = aws_lakeformation_resource.raw_data_location.arn
}
