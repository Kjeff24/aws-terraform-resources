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
