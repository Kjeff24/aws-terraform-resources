resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  raw_data_bucket_name = "${var.project_name}-raw-data-bucket-${random_id.suffix.hex}"
  processed_data_bucket_name = "${var.project_name}-processed-data-bucket-${random_id.suffix.hex}"
}

# Create S3 buckets for raw data
resource "aws_s3_bucket" "raw_data_bucket" {
  bucket        = local.raw_data_bucket_name
  force_destroy = true

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

# Create S3 buckets for processed data
resource "aws_s3_bucket" "processed_data_bucket" {
  bucket        = local.processed_data_bucket_name
  force_destroy = true

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


# Upload all files in the 'files' directory recursively
resource "aws_s3_object" "site_files" {
  for_each = fileset("${path.root}/files", "**/*.{csv,txt}")

  bucket = aws_s3_bucket.raw_data_bucket.id
  key    = each.value
  source = "${path.root}/files/${each.value}"
  etag   = filemd5("${path.root}/files/${each.value}")

  # Automatically set content type based on file extension
  content_type = lookup(
    {
      csv = "text/csv"
      txt = "text/plain"
    },
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "binary/octet-stream"
  )
}

# Upload Glue ETL scripts to processed bucket under 'scripts/'
resource "aws_s3_object" "glue_scripts" {
  for_each = fileset("${path.root}/scripts", "**/*.py")

  bucket = aws_s3_bucket.processed_data_bucket.id
  key    = "scripts/${each.value}"
  source = "${path.root}/scripts/${each.value}"
  etag   = filemd5("${path.root}/scripts/${each.value}")

  content_type = "text/x-python"
}