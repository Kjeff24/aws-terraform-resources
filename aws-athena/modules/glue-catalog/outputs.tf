output "database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.database.name
}

output "database_arn" {
  description = "ARN of the Glue database"
  value       = aws_glue_catalog_database.database.arn
}

output "table_names" {
  description = "List of created Glue table names"
  value       = [for table in aws_glue_catalog_table.tables : table.name]
}

output "table_arns" {
  description = "Map of Glue table ARNs (key: table name, value: table ARN)"
  value       = { for k, v in aws_glue_catalog_table.tables : k => v.arn }
}
