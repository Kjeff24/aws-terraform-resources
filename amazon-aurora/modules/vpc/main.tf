/*
Module: VPC Networking for Aurora

Description:
- Provisions isolated networking for the Aurora cluster, including a VPC,
  private subnets across multiple AZs, and a security group that restricts
  database access to within the VPC only.

Creates:
- aws_vpc.main
- aws_subnet.private (count)
- aws_security_group.aurora

Inputs:
- var.project_name (string)
- var.vpc_cidr (string)
- var.availability_zones (list(string))
- var.private_subnet_cidrs (list(string))
- var.aurora_port (number)

Notes:
- No IGW or NAT Gateway — Aurora runs in fully private subnets.
- Security group allows inbound on the Aurora port from within the VPC CIDR only.
*/

# 🌐 VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "${var.project_name}-vpc"
    ResourceName = "VPC"
  }
}
