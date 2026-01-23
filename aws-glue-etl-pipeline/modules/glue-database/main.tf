/*
Glue Database Module - Data Catalog Database

This module creates the AWS Glue Catalog Database that serves as a container
for metadata about raw CSV data. The database is used by:
- Glue Crawler to store discovered table schemas
- Glue ETL Job to read table definitions
- Lake Formation for fine-grained access control
*/

# Glue Catalog Database
resource "aws_glue_catalog_database" "raw_data" {
  name        = "${replace(var.project_name, "-", "_")}_raw_data"
  description = "Glue Catalog database for raw CSV data"
  tags = {
    Name = "${replace(var.project_name, "-", "_")}_raw_data"
  }
}
