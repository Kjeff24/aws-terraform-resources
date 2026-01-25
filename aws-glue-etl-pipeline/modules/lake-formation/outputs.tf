output "resource_arn" {
  description = "ARN of the registered Lake Formation resource"
  value       = aws_lakeformation_resource.raw_data_location.arn
}

output "data_location_permissions_id" {
  description = "ID of the data location permissions resource (for dependency tracking)"
  value       = aws_lakeformation_permissions.data_location_permissions.id
}
