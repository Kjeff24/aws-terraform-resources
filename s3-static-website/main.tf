/**
  Frontend stack for the web-ec2-scenario.

  What it provisions:
  - module.s3: Static site S3 bucket used as the CloudFront origin and for static assets
  - module.cloudfront: CloudFront distribution configured to use the S3 origin

  Cross-module wiring and notes:
  - `module.s3` produces S3 outputs (bucket id, ARN, regional domain name) that
    are passed into the CloudFront module as the origin.
  - This root configuration passes logging-related variables into the
    CloudFront module when `var.enable_logging` is true. In that case:
      - `module.s3` will create a dedicated logs bucket and expose
        `module.s3.cloudfront_logs_bucket_id`.
      - The root forwards that bucket name into `module.cloudfront.logging_bucket`.
      - The CloudFront module will configure `logging_config` only when both
        `enable_logging` is true and a `logging_bucket` name is provided.
  - This root configuration does not itself create an ALB or Lambda@Edge
    resources. If you require ALB proxying or Lambda@Edge associations you must
    add those resources and wire their outputs into the CloudFront module
    (the current `modules/cloudfront` implementation only creates an OAC and
    a CloudFront distribution with a single S3 origin).

  Inputs (selected):
  - project_name, region, tags
  - default_root_object, cloudfront_price_class, cloudfront_alias
  - enable_logging (bool) — if true, `module.s3` will create a logs bucket and
    its id will be passed to `module.cloudfront.logging_bucket` to enable CloudFront access logging.
*/
# S3 module
module "s3" {
  source                      = "./modules/s3"
  project_name                = var.project_name
  tags                        = var.tags
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  enable_logging = var.enable_logging
}

# CloudFront module
module "cloudfront" {
  source                 = "./modules/cloudfront"
  region                 = var.region
  project_name           = var.project_name
  tags                   = var.tags
  s3_origin_id           = module.s3.bucket_id
  s3_bucket_domain       = module.s3.bucket_regional_domain_name
  s3_bucket_arn          = module.s3.bucket_arn
  default_root_object    = var.default_root_object
  cloudfront_price_class = var.cloudfront_price_class
  cloudfront_aliases     = [var.cloudfront_alias]
  enable_logging         = var.enable_logging
  logging_bucket         = module.s3.cloudfront_logs_bucket_id
  logging_include_cookies = var.logging_include_cookies
  logging_prefix = var.logging_prefix
}