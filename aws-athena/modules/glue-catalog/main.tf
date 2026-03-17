/*
Glue Data Catalog Module - Database and Tables

This module creates Glue Data Catalog resources for Athena:
- Glue Database: Container for tables
- Glue Tables: Metadata definitions for data in S3
*/

# Glue Database
resource "aws_glue_catalog_database" "database" {
  name        = var.database_name
  description = var.database_description

  parameters = {
    "comment" = var.database_description
  }

  tags = {
    Name = "${var.project_name}-glue-database"
  }
}

# Glue Tables
resource "aws_glue_catalog_table" "tables" {
  for_each = var.tables

  name          = each.key
  database_name = aws_glue_catalog_database.database.name
  description   = each.value.description

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
    "typeOfData"     = "file"
  }

  storage_descriptor {
    location      = each.value.location
    input_format  = each.value.input_format
    output_format = each.value.output_format

    ser_de_info {
      name                  = "${each.key}_serde"
      serialization_library = each.value.serde_library
    }

    dynamic "columns" {
      for_each = each.value.columns
      content {
        name = columns.value.name
        type = columns.value.type
      }
    }
  }

  dynamic "partition_keys" {
    for_each = each.value.partition_keys != null ? each.value.partition_keys : []
    content {
      name = partition_keys.value.name
      type = partition_keys.value.type
    }
  }

}
