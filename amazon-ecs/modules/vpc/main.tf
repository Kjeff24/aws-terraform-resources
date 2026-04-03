/*
Module: VPC Networking

Description:
- Provisions the core networking infrastructure for the ECS workload, including
  a VPC, public and private subnets across multiple AZs, an Internet Gateway,
  a NAT Gateway for private subnet egress, route tables, and security groups
  for the ALB and ECS tasks.

Creates:
- aws_vpc.main
- aws_internet_gateway.main
- aws_subnet.public (count)
- aws_subnet.private (count)
- aws_eip.nat
- aws_nat_gateway.main
- aws_route_table.public + aws_route_table_association.public
- aws_route_table.private + aws_route_table_association.private
- aws_security_group.alb
- aws_security_group.ecs

Inputs:
- var.region (string)
- var.project_name (string)
- var.vpc_cidr (string)
- var.availability_zones (list(string))
- var.public_subnet_cidrs (list(string))
- var.private_subnet_cidrs (list(string))
- var.container_port (number)

Notes:
- NAT Gateway is deployed in the first public subnet only.
- ECS security group allows inbound traffic only from the ALB security group.
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

# 🌍 Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name         = "${var.project_name}-igw"
    ResourceName = "InternetGateway"
  }
}

# 🌐 Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name         = "${var.project_name}-public-subnet-${count.index + 1}"
    ResourceName = "PublicSubnet"
    Type         = "Public"
  }
}

# 🔒 Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name         = "${var.project_name}-private-subnet-${count.index + 1}"
    ResourceName = "PrivateSubnet"
    Type         = "Private"
  }
}

# 🌍 Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name         = "${var.project_name}-nat-eip"
    ResourceName = "EIP"
  }
}

# 🔁 NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name         = "${var.project_name}-nat-gw"
    ResourceName = "NATGateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# 🛣️ Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name         = "${var.project_name}-public-rt"
    ResourceName = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 🛣️ Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name         = "${var.project_name}-private-rt"
    ResourceName = "PrivateRouteTable"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# 🔒 ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound traffic to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-alb-sg"
    ResourceName = "ALBSecurityGroup"
  }
}

# 🔒 ECS Security Group
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "${var.project_name}-ecs-sg"
    ResourceName = "ECSSecurityGroup"
  }
}
