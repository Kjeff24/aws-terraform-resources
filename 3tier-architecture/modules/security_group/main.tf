/**
  Security groups for ALB (public), App (private), and DB layers.
  - alb_sg: allows 80/443 from internet
  - private_sg: allows app_port from ALB SG; ICMP from VPC CIDR
  - db_sg: allows db_port from private SG; ICMP from VPC CIDR

  Inputs: project_name, vpc_id, vpc_cidr, app_port, db_port, tags
  Outputs: alb_public_sg_id, app_private_sg_id, db_sg_id
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

# ====================================================
# PUBLIC SECURITY GROUP (WEB LAYER)
# ====================================================

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound access to ALB from anywhere"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow TCP on port ${var.app_port}"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = local.egress_all.from_port
    to_port     = local.egress_all.to_port
    protocol    = local.egress_all.protocol
    cidr_blocks = local.egress_all.cidr_blocks
  }

  tags = merge(var.tags, {
    Name         = "Public Layer Security Group"
    ResourceName = "Public-Layer-SG"
  })
}

# ====================================================
# PRIVATE SECURITY GROUP (APPLICATION LAYER)
# ====================================================

resource "aws_security_group" "private_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow app traffic from ALB (Public SG) only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow TCP on port ${var.app_port} from ALB SG"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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

  tags = merge(var.tags, {
    Name         = "Private App Security Group"
    ResourceName = "Private-App-SG"
  })
}

# ====================================================
# DATABASE SECURITY GROUP (DB LAYER)
# ====================================================

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow DB access from Private SG only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB access from Private SG on port ${var.db_port}"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.private_sg.id]
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

  tags = merge(var.tags, {
    Name         = "Database Security Group"
    ResourceName = "Database-SG"
  })
}