/*
Glue Database Module - Data Catalog Database for Raw Data

This module creates the AWS Glue Catalog Database that serves as a container
for metadata about raw data. The database is used by:
- Glue Crawler to store discovered table schemas
- Glue ETL Job to read table definitions
*/

# Glue Catalog Database for raw data
resource "aws_glue_catalog_database" "raw_data" {
  name        = "${replace(var.project_name, "-", "_")}_raw_data"
  description = var.description

  tags = {
    Name = "${var.project_name}-raw-data-database"
  }
}
