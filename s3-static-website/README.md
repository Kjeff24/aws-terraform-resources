
# s3-static-website

Static website deployment using Terraform, S3 and CloudFront.

## What this repo contains

This project provisions an S3-backed static website and a CloudFront distribution to serve it via a CDN. The website files are under the `files/` directory and two modules are provided to separate concerns:

- `modules/s3` — creates the S3 bucket, bucket policy, and optional website configuration.
- `modules/cloudfront` — creates a CloudFront distribution and connects it to the S3 origin.

Terraform root files live at the repository root and wire the modules together.

## Repo structure

```
s3-static-website/
├── backend.tf                — Terraform backend configuration (optional)
├── main.tf                   — Root module wiring (S3 + CloudFront)
├── outputs.tf                — Root-level outputs
├── variables.tf              — Root-level variables
├── README.md                 — Project documentation
├── files/                    — Static website assets
│   ├── index.html            — Site homepage (project README content embedded)
│   ├── index.js              — Small client-side interactions
│   └── style.css             — Styles for the site and markdown
└── modules/                  — Reusable Terraform modules
	├── cloudfront/           — CloudFront distribution module
	│   ├── main.tf
	│   ├── outputs.tf
	│   └── variables.tf
	└── s3/                   — S3 bucket and optional logs bucket
		├── main.tf
		├── outputs.tf
		└── variables.tf
```

## Prerequisites

- Terraform (recommended v1.12+)
- An AWS account and credentials configured in your environment (AWS CLI, environment variables or credential file)

Configure AWS credentials in one of the usual ways. Example using environment variables on macOS (zsh):

```zsh
export AWS_ACCESS_KEY_ID="your_key_here"
export AWS_SECRET_ACCESS_KEY="your_secret_here"
export AWS_DEFAULT_REGION="eu-west-1"
```

## Quick start — deploy the website

1. Initialize Terraform

```zsh
terraform init
```

2. (Optional) Review plan

```zsh
terraform plan -out plan.tfplan
```

3. Apply

```zsh
terraform apply "plan.tfplan"
# or
terraform apply -auto-approve
```

After apply completes, you will have an S3 bucket and a CloudFront distribution created by this configuration.

Note about CloudFront in this repo: the root `main.tf` includes the `modules/cloudfront` module unconditionally, so a CloudFront distribution is created by default. The repo currently uses `var.enable_logging` to control whether a logs bucket is created and passed to CloudFront.

## Variables

Root-level variables are declared in `variables.tf`. The most commonly adjusted ones are:

The root `variables.tf` exposes several options used by the S3 and CloudFront modules. Common variables in this repo include:

- `region` — AWS region for resources (default in `variables.tf`)
- `project_name` — used for resource naming and tagging
- `tags` — map of tags applied to resources
- `enable_logging` — whether to create a dedicated CloudFront logs bucket (bool)

CloudFront-specific variables present in `variables.tf` (used by the `modules/cloudfront`) include:

- `cloudfront_price_class` — CloudFront price class (PriceClass_100/200/All)
- `default_root_object` — default root object served by CloudFront (e.g., `index.html`)
- `cloudfront_alias` — optional CNAME for CloudFront (e.g., `cdn.example.com`)
- `logging_prefix` — prefix for logs in the logging bucket
- `logging_include_cookies` — whether to include cookies in CloudFront access logs

You can pass values by creating a `terraform.tfvars` file or by setting `-var` flags. Example `terraform.tfvars`:

```
region = "eu-west-1"
project_name = "my-site"
enable_logging = false
```

## Outputs

After apply, you can inspect outputs and module outputs to find the created resource identifiers:

- `s3_bucket_name` — created bucket name (if exposed at root)
- `s3_website_endpoint` — S3 website endpoint (if website hosting enabled and exposed at root)

The CloudFront module (see `modules/cloudfront/outputs.tf`) exposes the following outputs:

- `domain_name` — the CloudFront distribution domain (e.g., d1234abcd.cloudfront.net)
- `distribution_arn` — the distribution ARN

Because the root `outputs.tf` in this repo is currently empty, those module outputs are not forwarded to the root-level `terraform output` command by default. To expose the CloudFront domain at the root so you can run `terraform output cloudfront_domain_name`, add a root output like this to `outputs.tf`:

```terraform
output "cloudfront_domain_name" {
	description = "CloudFront distribution domain name"
	value       = module.cloudfront.domain_name
}
```

After adding that root output and re-applying (or refreshing state), you can run:

```zsh
terraform output cloudfront_domain_name
# => d1234abcd.cloudfront.net
```

Making CloudFront optional

If you prefer CloudFront to be optional (so the root only creates S3 by default), add a boolean variable such as `enable_cloudfront` to `variables.tf` and guard the module with a `count = var.enable_cloudfront ? 1 : 0` or conditional `for_each`. If you want, I can add that change and update wiring for you.

## Local testing

You can preview the static files locally before deploying. From the `files/` folder run a simple HTTP server (Python 3):

```zsh
cd files
python3 -m http.server 8000
# open http://localhost:8000
```

## Cleaning up / destroy

To remove all resources created by Terraform run:

```zsh
terraform destroy -auto-approve
```

Important: S3 buckets containing objects may fail to be destroyed until the bucket is emptied. If a `terraform destroy` fails because the bucket isn't empty, you can either empty it manually or use a lifecycle/automation to remove objects first. Be careful — you will permanently delete your site assets.

## Notes and best practices

- Ensure your S3 bucket name is globally unique if you provide custom names.
- For production use, consider using a certificate (ACM) and a custom domain; CloudFront + ACM in eu-west-1 is common for global distributions.
- The `backend.tf` can be configured to use an S3 backend and DynamoDB for state locking — recommended for team usage.
- Validate IAM permissions: the credentials you use must be able to create S3 buckets, put bucket policies, create CloudFront distributions, and manage related resources.

## License

MIT
