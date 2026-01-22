/*
Lake Formation Module - Fine-Grained Access Control

This module configures AWS Lake Formation for secure data access:
- Resource Registration: Registers S3 bucket location with Lake Formation
  to enable centralized access control
- Data Location Permissions: Grants the Glue IAM role permission to
  access data in the registered S3 location
- Database Permissions: Grants CREATE_TABLE permission to allow the
  crawler to create tables in the Glue Catalog database
This module is conditionally created when enable_lake_formation is true
*/

# Register S3 Location in Lake Formation
resource "aws_lakeformation_resource" "raw_data_location" {
  arn      = var.raw_data_bucket_arn
  role_arn = var.glue_service_role_arn
}

# Grant Data Location Permissions to Glue IAM Role
resource "aws_lakeformation_permissions" "data_location_permissions" {
  principal   = var.glue_service_role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.raw_data_bucket_arn
  }

  depends_on = [aws_lakeformation_resource.raw_data_location]
}

# Grant Database Permissions to Glue IAM Role
resource "aws_lakeformation_permissions" "database_permissions" {
  principal   = var.glue_service_role_arn
  permissions = var.database_permissions

  database {
    name = var.catalog_database_name
  }

  depends_on = [aws_lakeformation_resource.raw_data_location]
}
