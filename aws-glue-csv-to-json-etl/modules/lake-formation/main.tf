############################
# Register S3 Location in Lake Formation
############################
resource "aws_lakeformation_resource" "raw_data_location" {
  arn      = var.raw_data_bucket_arn
  role_arn = var.glue_service_role_arn
}

############################
# Grant Data Location Permissions to Glue IAM Role
############################
resource "aws_lakeformation_permissions" "data_location_permissions" {
  principal   = var.glue_service_role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.raw_data_bucket_arn
  }

  depends_on = [aws_lakeformation_resource.raw_data_location]
}

############################
# Grant Database Permissions to Glue IAM Role
############################
resource "aws_lakeformation_permissions" "database_permissions" {
  principal   = var.glue_service_role_arn
  permissions = ["CREATE_TABLE"]

  database {
    name = var.catalog_database_name
  }

  depends_on = [aws_lakeformation_resource.raw_data_location]
}
