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

### Core Networking Configuration

Single object variable `var.networking` controls the VPC layout:

- `vpc_cidr` (string): VPC CIDR, e.g. `"10.0.0.0/16"`
- `public_subnet_count` (number): Number of public subnets (>= 1)
- `private_subnet_count` (number): Number of private subnets (>= 1)
- `subnet_prefix_length` (number): Subnet mask length (e.g., 24). Determines the size of each subnet.
- `enable_dns_hostnames` (bool): Enable DNS hostnames in the VPC (default: true)
- `enable_dns_support` (bool): Enable DNS support in the VPC (default: true)
- `public_subnet_index_start` (optional number): Starting index for public subnets (default: 0). Use this to reserve IP ranges for future expansion.
- `private_subnet_index_start` (optional number): Starting index for private subnets (default: `public_subnet_index_start + public_subnet_count`). Use this to reserve IP ranges between public and private subnets.

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
- subnet index ranges don't overlap

### Understanding Subnet Capacity

The module uses Terraform's `cidrsubnet()` function to calculate subnet CIDR blocks. The formula is:

**Subnet Capacity Calculation:**
- `subnet_newbits = subnet_prefix_length - vpc_prefix_length`
- **Total possible subnets = 2^subnet_newbits**

**Example with default configuration:**
- VPC CIDR: `10.0.0.0/16` (prefix length: 16)
- Subnet prefix: `/24` (prefix length: 24)
- `subnet_newbits = 24 - 16 = 8`
- **Total possible subnets = 2^8 = 256 subnets**

**IP Addresses per Subnet:**
- Each `/24` subnet provides: **256 total IPs** (2^8)
- AWS reserves 5 IPs per subnet (network, broadcast, AWS services)
- **Usable IPs per subnet: 251**

**Default Configuration Example:**
With `vpc_cidr = "10.0.0.0/16"`, `public_subnet_count = 2`, `private_subnet_count = 2`, `subnet_prefix_length = 24`:

- **Public subnets:**
  - Index 0: `10.0.0.0/24` (251 usable IPs)
  - Index 1: `10.0.1.0/24` (251 usable IPs)
- **Private subnets:**
  - Index 2: `10.0.2.0/24` (251 usable IPs)
  - Index 3: `10.0.3.0/24` (251 usable IPs)
- **Total usable IPs:** 1,004 IPs (4 subnets × 251)
- **Available for expansion:** 252 subnets (indices 4-255)

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
  # Optional: Reserve IP ranges for future expansion
  # public_subnet_index_start  = 0   # Public subnets start at index 0 (default)
  # private_subnet_index_start = 100 # Private subnets start at index 100, leaving 0-99 for public expansion
}
```

**Example: Reserving IP ranges for future expansion**

For a `/16` VPC with `/24` subnets (256 possible subnets), you can reserve ranges:

```hcl
networking = {
  vpc_cidr                  = "10.0.0.0/16"
  public_subnet_count       = 2
  private_subnet_count      = 2
  subnet_prefix_length      = 24
  public_subnet_index_start = 0   # Public: indices 0-1 (can expand to 0-9)
  private_subnet_index_start = 100 # Private: indices 100-101 (can expand to 100-109)
  # This leaves indices 2-99 and 102-255 available for future use
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

- **AZ cycling**: If you request more subnets than available AZs, subnets round‑robin across AZs.
- **NAT strategy**: This stack provisions one NAT Gateway (in the first public subnet) to minimize cost. For HA egress, consider one NAT per AZ and per‑AZ private route tables.
- **Tagging**: Subnets and route tables include `Name` and `ResourceName` tags for clarity.
- **Subnet allocation strategy**: By default, subnets are allocated sequentially starting from index 0. To reserve IP ranges for future expansion without recreating existing subnets, use `public_subnet_index_start` and `private_subnet_index_start` to specify where each subnet type should start. For example, with a `/16` VPC and `/24` subnets (256 possible subnets), you could reserve:
  - Indices 0-9: Public subnets (start at 0, create 2-10 as needed)
  - Indices 10-99: Reserved for future public expansion
  - Indices 100-109: Private subnets (start at 100, create 2-10 as needed)
  - Indices 110-255: Reserved for future expansion
- **Manually adding subnets**: You can manually create subnets in the AWS console, but they won't be managed by Terraform. You'll need to manually associate them with route tables. For consistency, it's recommended to manage all subnets through Terraform by adjusting subnet counts or using the index start parameters to reserve ranges.

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
- `cidrsubnet()` derivation based on `var.networking.subnet_prefix_length`
  - Calculates `subnet_newbits = subnet_prefix_length - vpc_prefix_length`
  - Uses `cidrsubnet(vpc_cidr, subnet_newbits, index)` to generate subnet CIDRs
- Public/private route tables and associations
- NAT EIP + NAT Gateway in the first public subnet

### How Subnet CIDRs are Calculated

The module uses Terraform's `cidrsubnet()` function with the formula:
```
cidrsubnet(vpc_cidr, subnet_newbits, subnet_index)
```

Where:
- `vpc_cidr`: The VPC CIDR block (e.g., `"10.0.0.0/16"`)
- `subnet_newbits`: Additional bits beyond the VPC prefix (calculated as `subnet_prefix_length - vpc_prefix_length`)
- `subnet_index`: The subnet number/index (0, 1, 2, etc.)

**Example calculation:**
- VPC: `10.0.0.0/16`, Subnet prefix: `/24`
- `subnet_newbits = 24 - 16 = 8`
- Public subnet index 0: `cidrsubnet("10.0.0.0/16", 8, 0)` → `10.0.0.0/24`
- Public subnet index 1: `cidrsubnet("10.0.0.0/16", 8, 1)` → `10.0.1.0/24`
- Private subnet index 2: `cidrsubnet("10.0.0.0/16", 8, 2)` → `10.0.2.0/24`
