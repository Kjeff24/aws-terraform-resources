/**
 * ============================================================================
 *  CloudFront distribution (S3 origin) — module header
 *  ----------------------------------------------------------------------------
 *  This file creates the following resources:
 *    - aws_cloudfront_origin_access_control.website_oac
 *    - aws_cloudfront_distribution.s3_distribution
 *
 *  Summary:
 *    - Creates an Origin Access Control (OAC) for signing CloudFront requests
 *      to the configured S3 origin so the bucket can remain private.
 *    - Creates a CloudFront distribution with a single S3 origin and a
 *      default cache behavior targeting that origin.
 *
 *  Variables referenced in this file:
 *    - var.s3_origin_id
 *    - var.s3_bucket_domain
 *    - var.default_root_object
 *    - var.cloudfront_price_class
 *    - var.tags
 *    - var.project_name
 *
 *  Notes:
 *    - The module uses a hard-coded AWS-managed cache policy id for the
 *      default_cache_behavior; replace it with your own policy if you need to
 *      forward headers, cookies, or query strings to the origin.
 *    - Aliases/custom domains and ACM certificates are not configured here.
 *      If you enable aliases, supply an ACM cert in us-east-1 and update
 *      `viewer_certificate` and `aliases` accordingly.
 *    - This module does not create ALB origins or Lambda@Edge associations.
 *      Remove references to those features unless you actually add the
 *      corresponding resources.
 * ============================================================================
 */

# Create an Origin Access Control (OAC) to secure the S3 bucket
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.s3_origin_id}-oac"
  description                       = "OAC for S3 origin ${var.s3_origin_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create the CloudFront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true
  # aliases = var.cloudfront_aliases
  default_root_object = var.default_root_object
  price_class         = var.cloudfront_price_class

  # Define the S3 origin with OAC
  origin {
    domain_name              = var.s3_bucket_domain
    origin_id                = var.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  # Optional CloudFront access logging - enabled when both `enable_logging` is true
  # and a `logging_bucket` name is provided. CloudFront expects the S3 bucket
  # in the form `bucket-name.s3.amazonaws.com`.
  dynamic "logging_config" {
    for_each = (var.enable_logging && var.logging_bucket != "") ? [1] : []
    content {
      bucket          = "${var.logging_bucket}.s3.amazonaws.com"
      include_cookies = var.logging_include_cookies
      prefix          = var.logging_prefix
    }
  }

  # Default Behavior (Static content from S3)
  default_cache_behavior {
    target_origin_id       = var.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-${var.s3_origin_id}-oac"
  }
}

