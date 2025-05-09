/**
  Single security group for EC2 instances.
  - Allows optional SSH (22) and HTTP (80) from provided CIDR lists
  - Allows ICMP from VPC CIDR for diagnostics

  Inputs: project_name, vpc_id, vpc_cidr, ssh_allowed_cidrs, http_allowed_cidrs, tags
  Output: ec2_sg_id
*/

# ====================================================
# LOCALS
# ====================================================
locals {
  egress_all = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow SSH/HTTP from allowed CIDRs and ICMP from VPC"
  vpc_id      = var.vpc_id

  # Allow SSH directly to instances from specified CIDR ranges
  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "SSH access from ${ingress.value}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Allow HTTP directly to instances from specified CIDR ranges
  dynamic "ingress" {
    for_each = var.http_allowed_cidrs
    content {
      description = "HTTP access from ${ingress.value}"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  ingress {
    description = "Allow ICMP (ping) from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = local.egress_all.from_port
    to_port     = local.egress_all.to_port
    protocol    = local.egress_all.protocol
    cidr_blocks = local.egress_all.cidr_blocks
  }

  tags = {
    ResourceName = "ec2-security-group"
  }

}
