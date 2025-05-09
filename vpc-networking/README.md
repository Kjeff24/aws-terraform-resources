# VPC Networking (Terraform)

Provision an AWS VPC with public and private subnets across Availability Zones, an Internet Gateway, a single NAT Gateway, and routed associations. Subnet CIDRs are derived automatically from the VPC CIDR using a configurable subnet prefix length. When requested subnet counts exceed the number of AZs, AZ assignment cycles across available zones.

## Features

- VPC with configurable DNS hostnames/support (enabled by default)
- Public and private subnets derived with `cidrsubnet`
- AZ-aware placement with cycling when counts > AZs
- Internet Gateway and one cost‑effective NAT Gateway by default
- Route tables for public and private subnets with associations
- Clean outputs for VPC, subnets, route tables, IGW, and NAT

## Prerequisites

- Terraform CLI v1.x
- AWS credentials configured (e.g., via environment, shared config, or SSO)
- AWS provider v5+ (tested with v6.18.0)

A backend is already defined in `backend.tf` (update it with your s3 bucket for state management).

## Inputs

Single object variable `var.networking` controls the VPC layout:

- `vpc_cidr` (string): VPC CIDR, e.g. `"10.0.0.0/16"`
- `public_subnet_count` (number): Number of public subnets (>= 1)
- `private_subnet_count` (number): Number of private subnets (>= 1)
- `subnet_prefix_length` (number): Subnet mask length (e.g., 24)
- `enable_dns_hostnames` (bool): Enable DNS hostnames in the VPC (default: true)
- `enable_dns_support` (bool): Enable DNS support in the VPC (default: true)

Defaults (see `variables.tf`):

- vpc_cidr: `10.0.0.0/16`
- public_subnet_count: `2`
- private_subnet_count: `2`
- subnet_prefix_length: `24`
 - enable_dns_hostnames: `true`
 - enable_dns_support: `true`

Validation ensures:
- `vpc_cidr` is a valid IPv4 CIDR
- counts > 0
- `subnet_prefix_length` is between the VPC prefix and /28
- total requested subnets fit within the VPC capacity at that subnet size
- if `enable_dns_hostnames` is true, `enable_dns_support` must also be true

## Outputs

From the root (`vpc-networking/outputs.tf` forwards module outputs):

- `vpc_id`, `vpc_cidr`, `availability_zones`
- `public_subnet_ids`, `public_subnet_cidrs`
- `private_subnet_ids`, `private_subnet_cidrs`
- `internet_gateway_id`
- `nat_gateway_id`, `nat_eip_allocation_id`, `nat_eip_public_ip`
- `public_route_table_id`, `private_route_table_id`

## Quick start

1) Adjust inputs in `variables.tf` or create a `terraform.tfvars`:

```hcl
networking = {
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_count  = 3
  private_subnet_count = 3
  subnet_prefix_length = 24
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

2) Initialize and apply:

```sh
terraform init
terraform plan
terraform apply
```

3) Inspect outputs (examples):

- VPC ID: `vpc_id`
- Public subnets: `public_subnet_ids`
- NAT public IP: `nat_eip_public_ip`

4) Destroy when finished:

```sh
terraform destroy
```

## Notes

- AZ cycling: if you request more subnets than available AZs, subnets round‑robin across AZs.
- NAT strategy: this stack provisions one NAT Gateway (in the first public subnet) to minimize cost. For HA egress, consider one NAT per AZ and per‑AZ private route tables.
- Tagging: Subnets and route tables include `Name` and `ResourceName` tags for clarity.

## Module wiring

The root calls a single module (`modules/vpc`):

```hcl
module "vpc" {
  source     = "./modules/vpc"
  networking = var.networking
}
```

The module implements:
- AZ discovery (`data.aws_availability_zones`)
- `cidrsubnet` derivation based on `var.networking.subnet_prefix_length`
- public/private route tables and associations
- NAT EIP + NAT Gateway in the first public subnet
