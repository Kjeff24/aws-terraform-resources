output "crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.csv_crawler.name
}

output "crawler_arn" {
  description = "ARN of the Glue crawler"
  value       = aws_glue_crawler.csv_crawler.arn
}

output "catalog_database_name" {
  description = "Name of the Glue Catalog database"
  value       = var.catalog_database_name
}

output "catalog_database_arn" {
  description = "ARN of the Glue Catalog database"
  value       = null  # Database ARN is available from glue-database module
}
