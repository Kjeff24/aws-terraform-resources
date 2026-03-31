/*
Module: Aurora Cluster

Description:
- Provisions an Aurora cluster supporting both MySQL and PostgreSQL engines,
  with provisioned or Serverless v2 instances. Master password is managed
  automatically by AWS Secrets Manager via manage_master_user_password.

Creates:
- aws_db_subnet_group.main
- aws_rds_cluster_parameter_group.main
- aws_db_parameter_group.main
- aws_rds_cluster.main
- aws_rds_cluster_instance.main (count)

Inputs:
- var.project_name (string)
- var.private_subnet_ids (list(string))
- var.security_group_id (string)
- var.aurora_config (object):
  - engine (string)              "aurora-mysql" | "aurora-postgresql"
  - engine_version (string)
  - instance_class (string)      ignored when serverless_v2_scaling is set
  - instance_count (number)
  - database_name (string)
  - master_username (string)
  - serverless_v2_scaling (optional object):
    - min_capacity (number)
    - max_capacity (number)

Notes:
- Serverless v2 uses engine_mode="provisioned" with a serverless_v2_scaling block.
- instance_class is overridden to "db.serverless" when serverless_v2_scaling is set.
- master password is managed by AWS (rotated automatically in Secrets Manager).
*/

locals {
  port          = var.aurora_config.engine == "aurora-mysql" ? 3306 : 5432
  param_family  = var.aurora_config.engine == "aurora-mysql" ? "aurora-mysql8.0" : "aurora-postgresql15"
  is_serverless = var.aurora_config.serverless_v2_scaling != null
  instance_class = local.is_serverless ? "db.serverless" : var.aurora_config.instance_class
}

# 🗄️ DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name         = "${var.project_name}-subnet-group"
    ResourceName = "DBSubnetGroup"
  }
}

# ⚙️ Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "main" {
  name   = "${var.project_name}-cluster-pg"
  family = local.param_family

  tags = {
    Name         = "${var.project_name}-cluster-pg"
    ResourceName = "ClusterParameterGroup"
  }
}

# ⚙️ Instance Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-instance-pg"
  family = local.param_family

  tags = {
    Name         = "${var.project_name}-instance-pg"
    ResourceName = "InstanceParameterGroup"
  }
}

# 🗄️ Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier          = "${var.project_name}-cluster"
  engine                      = var.aurora_config.engine
  engine_version              = var.aurora_config.engine_version
  engine_mode                 = "provisioned"
  database_name               = var.aurora_config.database_name
  master_username             = var.aurora_config.master_username
  manage_master_user_password = true
  port                        = local.port
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [var.security_group_id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.project_name}-final-snapshot"
  storage_encrypted           = true

  dynamic "serverless_v2_scaling_configuration" {
    for_each = local.is_serverless ? [var.aurora_config.serverless_v2_scaling] : []
    content {
      min_capacity = serverless_v2_scaling_configuration.value.min_capacity
      max_capacity = serverless_v2_scaling_configuration.value.max_capacity
    }
  }

  tags = {
    Name         = "${var.project_name}-cluster"
    ResourceName = "AuroraCluster"
  }
}

# 🖥️ Aurora Cluster Instances
resource "aws_rds_cluster_instance" "main" {
  count                   = var.aurora_config.instance_count
  identifier              = "${var.project_name}-instance-${count.index + 1}"
  cluster_identifier      = aws_rds_cluster.main.id
  instance_class          = local.instance_class
  engine                  = aws_rds_cluster.main.engine
  engine_version          = aws_rds_cluster.main.engine_version
  db_subnet_group_name    = aws_db_subnet_group.main.name
  db_parameter_group_name = aws_db_parameter_group.main.name
  publicly_accessible     = false

  tags = {
    Name         = "${var.project_name}-instance-${count.index + 1}"
    ResourceName = "AuroraInstance"
    Role         = count.index == 0 ? "Writer" : "Reader"
  }
}
