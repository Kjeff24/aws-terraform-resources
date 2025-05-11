# EC2 Instance Terraform Stack

Provision a secure EC2 instance with a generated SSH key pair, opinionated security groups, and sane defaults. This stack composes three local modules:

- keypair: Generates or accepts an SSH key pair and exports its details
- security_groups: Creates a project-scoped EC2 security group
- ec2: Launches the EC2 instance, wiring in key pair, security groups, and optional user data

The configuration now includes robust input validation for instance_config to catch misconfiguration early.

## Prerequisites

- Terraform >= 1.12
- AWS credentials configured (AWS_PROFILE or environment variables)
- If using the remote backend in backend.tf: an existing S3 bucket and permissions to read/write state

## Getting started

By default, backend.tf points to an S3 bucket for state. For a quick local test without touching remote state:

```bash
cd ec2-instance
terraform init -backend=false
terraform validate
terraform plan
```

To use the configured S3 backend (recommended for team use):

```bash
cd ec2-instance
terraform init
terraform validate
terraform plan
```

Apply and destroy:

```bash
mkdir -p keys # required for key files written by the keypair module
terraform apply
terraform destroy
```

## Variables

- region (string, default: eu-west-1)
	- AWS region to deploy to. Note: the default AMI in instance_config is for us-east-1 and must be overridden or change region accordingly.
- project_name (string, default: my-site)
	- Used for naming/tagging resources
- tags (map(string))
	- Default tags applied via provider default_tags
- instance_config (object) — main EC2 settings:
	- ami_id (string): AMI to use
	- instance_type (string): e.g., t3.micro
	- subnet_id (string): empty to use defaults or supply a subnet id
	- key_name (string): optional; if empty, the generated key pair’s name is used automatically
	- associate_public_ip (bool): whether to assign a public IP
	- iam_instance_profile (string): empty, a profile name, or a valid instance profile ARN
	- disable_api_termination (bool): enables termination protection when true

### Validation rules for instance_config

These validations are enforced to surface configuration errors early:

- ami_id must match: ami-xxxxxxxx (hex)
- instance_type format: family.size (e.g., t3.micro)
- subnet_id: empty or subnet-xxxxxxxx (hex)
- key_name: empty or 1–255 chars of A–Z, a–z, 0–9, dot, underscore, hyphen
- iam_instance_profile: empty OR a simple name (A–Z, a–z, 0–9, +=,.@_-) OR a full ARN like arn:aws:iam::123456789012:instance-profile/Name

Tip: The default AMI value is an Amazon Linux 2 AMI for us-east-1. If you keep region = eu-west-1, set a valid AMI for eu-west-1.

## Outputs

- ec2_sg_id: ID of the default EC2 security group created by the security_groups module
- instance_id: ID of the EC2 instance
- public_ip: Public IP of the instance (if assigned)
- private_ip: Private IP of the instance
- public_dns: Public DNS name (if assigned)
- availability_zone: AZ where the instance is launched

Note: Some outputs depend on how the keypair module is configured. If you’re using the bundled keypair module, ensure the `keys/` directory exists so file outputs can be written.

## User data

The EC2 module references a user data template from the root module path:

```hcl
user_data = templatefile("${path.root}/user_data.sh", {})
```

- If you maintain your script at `scripts/user_data.sh`, either move it to the root as `user_data.sh` or update the module code to:

```hcl
user_data = templatefile("${path.root}/scripts/user_data.sh", {})
```

Ensure the script is executable and idempotent. Keep secrets out of VCS; prefer pulling from AWS SSM Parameter Store or Secrets Manager inside the script.

## Customization examples

Override the AMI for your region and pin a larger root volume:

```hcl
variable "instance_config" {
	default = {
		ami_id                   = "ami-0abcdef1234567890" # eu-west-1 AMI
		instance_type            = "t3.micro"
		subnet_id                = ""      
		key_name                 = ""            
		associate_public_ip      = true
		iam_instance_profile     = ""        
		disable_api_termination  = false
	}
}
```

Attach an existing instance profile by name or ARN:

```hcl
instance_config = merge(var.instance_config, {
	iam_instance_profile = "MyEc2InstanceProfile" # or "arn:aws:iam::123456789012:instance-profile/MyEc2InstanceProfile"
})
```

## Backend configuration

backend.tf is configured to use an S3 bucket:

```hcl
backend "s3" {
	bucket       = "aws-terraform-projects-state-bucket"
	key          = "ec2-instance/terraform.tfstate"
	region       = "eu-west-1"
	use_lockfile = true
}
```

For local experiments, disable the backend:

```bash
terraform init -backend=false
```

## Security notes

- The keypair module can generate and output a private key (sensitive); handle with care.
- Consider storing generated keys securely (e.g., AWS Secrets Manager) and restricting filesystem permissions.
- Set disable_api_termination = true to protect important instances.

## Troubleshooting

- Invalid AMI ID
	- Ensure the AMI exists in the selected region. The default AMI is for us-east-1; change it for eu-west-1.
- InvalidBlockDeviceMapping: Volume size is smaller than snapshot
	- Increase `instance_config.root_volume_size_gb` to at least the AMI’s snapshot size (often 8GB for Ubuntu/Amazon Linux). Default is now 8GB.
- IAM instance profile not found
	- If you pass a name, ensure the profile exists; with an ARN, verify the account id and name.
- Security group/id format errors
	- The validations enforce sg- and subnet- id formats; double-check the values.

## Project structure

```
.
├── README.md
├── backend.tf
├── main.tf
├── modules
│   ├── ec2
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── keypair
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── security_groups
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── scripts
│   └── user_data.sh
└── variable.tf
```
---

Maintainer tip: run terraform validate as you iterate to catch input mistakes early.

