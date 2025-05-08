/** 
 * ============================================================================
 *  S3 Bucket for Static Website Assets
 *  ----------------------------------------------------------------------------
 *  This configuration provisions a private Amazon S3 bucket to store static
 *  assets for a web application. It enforces strict access controls by blocking
 *  all forms of public access and allows only a specific CloudFront distribution
 *  to read objects from the bucket.
 *
 *  Key Features:
 *    - Creates a private S3 bucket for hosting static assets.
 *    - Blocks all public access at the bucket level.
 *    - Attaches a bucket policy granting CloudFront access via Origin Access Control (OAC).
 *    - Ensures secure delivery of content through CloudFront only.
 *    - Uploads static files from a local directory to the S3 bucket.
 *
 *  Variables Required:
 *    - var.bucket_name                 → Name of the S3 bucket.
 *    - var.cloudfront_distribution_arn → ARN of the CloudFront distribution.
 * ============================================================================
 */

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  static_site_bucket_name = "${var.project_name}-static-site-bucket-${random_id.suffix.hex}"
}

# Canonical user ID of the current AWS account (bucket owner) — used for ACL owner/grant definitions
data "aws_canonical_user_id" "current" {}

# Create a private S3 bucket for static assets
resource "aws_s3_bucket" "website_bucket" {
  bucket        = local.static_site_bucket_name
  force_destroy = true

  tags = {
    Name = "${var.project_name}-Static Website Bucket"
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "website_bucket_public_access_block" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#  Bucket policy to allow CloudFront to fetch objects from this private S3 bucket.
resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          "StringEquals" = {
            "aws:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

# Upload all files in the 'files' directory recursively
resource "aws_s3_object" "site_files" {
  for_each = fileset("${path.root}/files", "**")

  bucket = aws_s3_bucket.website_bucket.id
  key    = each.value
  source = "${path.root}/files/${each.value}"
  etag   = filemd5("${path.root}/files/${each.value}")

  # Automatically set content type based on file extension
  content_type = lookup(
    {
      html = "text/html",
      css  = "text/css",
      js   = "application/javascript",
      json = "application/json",
      png  = "image/png",
      jpg  = "image/jpeg",
      jpeg = "image/jpeg",
      svg  = "image/svg+xml",
      gif  = "image/gif",
      webp = "image/webp",
      ico  = "image/x-icon",
      txt  = "text/plain"
    },
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "binary/octet-stream"
  )
}

# Optional logging bucket for CloudFront access logs
resource "aws_s3_bucket" "cloudfront_logs_bucket" {
  count         = var.enable_logging ? 1 : 0
  bucket        = "${var.project_name}-cloudfront-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-CloudFront Logs Bucket"
  }
}

# Enable ACLs on the logs bucket so CloudFront can deliver standard access logs
resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_bucket_ownership" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs_bucket[0].id

  rule {
    # Allow ACLs while keeping bucket owner as preferred owner of new objects
    object_ownership = "BucketOwnerPreferred"
  }
}

# Apply the required ACL for CloudFront log delivery
resource "aws_s3_bucket_acl" "cloudfront_logs_bucket_acl" {
  count      = var.enable_logging ? 1 : 0
  bucket     = aws_s3_bucket.cloudfront_logs_bucket[0].id
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs_bucket_ownership]

  # Explicit ACL grants for CloudFront standard logging per AWS requirements
  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }

    # Ensure bucket owner retains full control
    grant {
      permission = "FULL_CONTROL"
      grantee {
        type = "CanonicalUser"
        id   = data.aws_canonical_user_id.current.id
      }
    }

    # Grant FULL_CONTROL to the AWS logs delivery canonical user for CloudFront
    # Canonical ID per AWS documentation: awslogsdelivery
    grant {
      permission = "FULL_CONTROL"
      grantee {
        type = "CanonicalUser"
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      }
    }
  }
}

# Block public access to the logs bucket (if created)
resource "aws_s3_bucket_public_access_block" "cloudfront_logs_public_access_block" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
