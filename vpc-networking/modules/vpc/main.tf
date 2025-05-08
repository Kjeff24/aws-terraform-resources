/**
 * ============================================================================
 * VPC networking module
 * ----------------------------------------------------------------------------
 * Provisions a VPC with public and private subnets spread across Availability
 * Zones, an Internet Gateway, a single NAT Gateway, and route tables with
 * associations. Subnet CIDRs are derived from the VPC CIDR using the
 * configured subnet prefix length. When requested subnet counts exceed the
 * number of AZs in the region, AZ assignment cycles across available AZs.
 *
 * Features
 * - Configurable VPC CIDR and subnet sizing via subnet_prefix_length
 * - Configurable counts for public and private subnets
 * - AZ cycling to support any subnet count in any region
 * - Cost‑effective default: single NAT in the first public subnet
 *
 * Inputs (var.networking)
 * - vpc_cidr             : string   (e.g., "10.0.0.0/16")
 * - public_subnet_count  : number   (>= 1)
 * - private_subnet_count : number   (>= 1)
 * - subnet_prefix_length : number   (e.g., 24)
 *
 * Notes
 * - Ensure (public_subnet_count + private_subnet_count) <= 2^(subnet_prefix_length - VPC prefix).
 * - For HA egress, consider one NAT per AZ and private route tables per AZ.
 * - Subnets and route tables are tagged with Name and ResourceName for clarity.
 * ============================================================================
 */

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs              = data.aws_availability_zones.available.names
  vpc_prefix_len   = tonumber(element(split("/", var.networking.vpc_cidr), 1))
  subnet_newbits   = max(0, var.networking.subnet_prefix_length - local.vpc_prefix_len)
  public_offset    = 0
  private_offset   = var.networking.public_subnet_count
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.networking.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    ResourceName = "main-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    ResourceName = "internet-gateway"
  }
}

# Public Subnets for ALB
resource "aws_subnet" "public" {
  count             = var.networking.public_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.networking.vpc_cidr, local.subnet_newbits, count.index + local.public_offset)
  availability_zone = local.azs[count.index % length(local.azs)]

  map_public_ip_on_launch = true

  tags = {
    Name         = "public-subnet-${count.index + 1}"
    ResourceName = "public-subnet-${count.index + 1}"
    Type         = "public"
  }
}

# Private Subnets for ECS Tasks
resource "aws_subnet" "private" {
  count             = var.networking.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.networking.vpc_cidr, local.subnet_newbits, count.index + local.private_offset)
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = {
    Name         = "private-subnet-${count.index + 1}"
    ResourceName = "private-subnet-${count.index + 1}"
    Type         = "private"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    ResourceName = "elastic-ip-nat-gateway"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id 

  tags = {
    ResourceName = "nat-gateway"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name         = "public-route-table"
    ResourceName = "public-route-table"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name         = "private-route-table"
    ResourceName = "private-route-table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = var.networking.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.networking.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
