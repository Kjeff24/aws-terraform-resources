################################################################################
# Glue Crawler Module - Data Discovery and Cataloging
################################################################################
# This module creates AWS Glue resources for discovering and cataloging data:
# - Glue Catalog Database: Container for metadata about raw CSV data
# - Glue Crawler: Automatically discovers CSV files in S3, infers schemas,
#   and creates table definitions in the Glue Data Catalog
# - Lake Formation Integration: Optionally configures crawler to use
#   Lake Formation credentials for fine-grained access control
# The crawler can run on-demand or on a schedule to keep the catalog updated
################################################################################

############################
# Data Sources
############################
data "aws_caller_identity" "current" {}

############################
# Glue Crawler
############################
resource "aws_glue_catalog_database" "raw_data" {
  name        = "${replace(var.project_name, "-", "_")}_raw_data"
  description = "Glue Catalog database for raw CSV data"
  tags = {
    Name = "${replace(var.project_name, "-", "_")}_raw_data"
  }
}

resource "aws_glue_crawler" "csv_crawler" {
  database_name = aws_glue_catalog_database.raw_data.name
  name          = "${var.project_name}-csv-crawler"
  role          = var.glue_service_role_arn
  description   = "Crawler to discover and catalog CSV files in S3"

  s3_target {
    path = "s3://${var.raw_data_bucket_name}/"
  }

  table_prefix = "raw_"

  # Optional schedule (null for on-demand)
  schedule = var.crawler_schedule

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  dynamic "lake_formation_configuration" {
    for_each = var.enable_lake_formation ? [1] : []
    content {
      use_lake_formation_credentials = true
      account_id                     = data.aws_caller_identity.current.account_id
    }
  }

  tags = {
    Name = "${var.project_name}-csv-crawler"
  }

  depends_on = [aws_glue_catalog_database.raw_data]
}
