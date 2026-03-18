/*
S3 Module - Storage for Raw Data, Processed Data, and Query Results

This module creates and manages S3 buckets for the integrated Glue ETL + Athena solution:
- Raw data bucket: Stores raw input data files (CSV, JSON, etc.) for Glue ETL processing
- Processed data bucket: Stores transformed/processed data files (Parquet, JSON, etc.) for Athena queries
- Query results bucket: Stores Athena query results
- Versioning: Configurable versioning for all buckets
- Encryption: Server-side encryption (SSE-S3 or SSE-KMS)
*/

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  raw_data_bucket_name       = "${var.project_name}-raw-data-${random_id.suffix.hex}"
  processed_data_bucket_name = "${var.project_name}-processed-data-${random_id.suffix.hex}"
  query_results_bucket_name  = "${var.project_name}-query-results-${random_id.suffix.hex}"
}

# Create S3 bucket for raw data (input for Glue ETL)
resource "aws_s3_bucket" "raw_data_bucket" {
  bucket        = local.raw_data_bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name = "${var.project_name}-raw-data-bucket"
  }
}

resource "aws_s3_bucket_versioning" "raw_data_bucket_versioning" {
  bucket = aws_s3_bucket.raw_data_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data_bucket_encryption" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.raw_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null
  }
}

# Create S3 bucket for processed data (output from Glue ETL, input for Athena)
resource "aws_s3_bucket" "processed_data_bucket" {
  bucket        = local.processed_data_bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name = "${var.project_name}-processed-data-bucket"
  }
}

resource "aws_s3_bucket_versioning" "processed_data_bucket_versioning" {
  bucket = aws_s3_bucket.processed_data_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data_bucket_encryption" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.processed_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null
  }
}

# Create S3 bucket for Athena query results
resource "aws_s3_bucket" "query_results_bucket" {
  bucket        = local.query_results_bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name = "${var.project_name}-query-results-bucket"
  }
}

resource "aws_s3_bucket_versioning" "query_results_bucket_versioning" {
  bucket = aws_s3_bucket.query_results_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "query_results_bucket_encryption" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.query_results_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null
  }
}

# Block public access for all buckets
resource "aws_s3_bucket_public_access_block" "raw_data_bucket" {
  bucket = aws_s3_bucket.raw_data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "processed_data_bucket" {
  bucket = aws_s3_bucket.processed_data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload all files from the 'files' directory to raw data bucket
# Files will be discovered by Glue Crawler
resource "aws_s3_object" "raw_data_files" {
  for_each = try(fileset("${path.root}/files", "**/*"), toset([]))

  bucket = aws_s3_bucket.raw_data_bucket.id
  key    = each.value
  source = "${path.root}/files/${each.value}"
  etag   = filemd5("${path.root}/files/${each.value}")

  # Automatically set content type based on file extension
  content_type = lookup(
    {
      csv     = "text/csv"
      txt     = "text/plain"
      json    = "application/json"
      parquet = "application/octet-stream"
    },
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "binary/octet-stream"
  )
}

# Upload Glue ETL scripts to processed data bucket (used as scripts bucket)
# Only upload if scripts directory exists
resource "aws_s3_object" "glue_scripts" {
  for_each = try(fileset("${path.root}/scripts", "**/*.{py,scala}"), toset([]))

  bucket = aws_s3_bucket.processed_data_bucket.id
  key    = "scripts/${each.value}"
  source = "${path.root}/scripts/${each.value}"
  etag   = filemd5("${path.root}/scripts/${each.value}")

  # Set content type based on file extension
  content_type = endswith(each.value, ".py") ? "text/x-python" : "text/x-scala"
}

resource "aws_s3_bucket_public_access_block" "query_results_bucket" {
  bucket = aws_s3_bucket.query_results_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
