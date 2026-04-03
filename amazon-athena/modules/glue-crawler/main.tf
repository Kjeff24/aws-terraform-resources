/*
Glue Crawler Module - Data Discovery and Cataloging

This module creates AWS Glue Crawler for discovering and cataloging data:
- Glue Crawler: Automatically discovers files in S3, infers schemas,
  and creates table definitions in the Glue Data Catalog
- The crawler references an existing Glue Catalog Database
- Can run on-demand or on a schedule to keep the catalog updated
*/

# Data Sources
data "aws_caller_identity" "current" {}

# Glue Crawler
resource "aws_glue_crawler" "data_crawler" {
  database_name = var.catalog_database_name
  name          = var.crawler_type == "raw" ? "${var.project_name}-raw-crawler" : "${var.project_name}-processed-crawler"
  role          = var.glue_service_role_arn
  description   = var.crawler_type == "raw" ? "Crawler to discover and catalog raw data files in S3" : "Crawler to discover and catalog processed data files in S3 (for Athena queries)"

  s3_target {
    path = var.crawler_type == "raw" ? "s3://${var.raw_data_bucket_name}/" : "s3://${var.processed_data_bucket_name}/"
  }

  table_prefix = var.table_prefix

  # Optional schedule (null for on-demand)
  schedule = var.crawler_schedule

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = {
    Name = var.crawler_type == "raw" ? "${var.project_name}-raw-crawler" : "${var.project_name}-processed-crawler"
  }
}
