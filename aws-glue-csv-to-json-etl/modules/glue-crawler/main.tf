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

  tags = {
    Name = "${var.project_name}-csv-crawler"
  }

  depends_on = [aws_glue_catalog_database.raw_data]
}
