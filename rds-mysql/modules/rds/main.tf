resource "aws_db_subnet_group" "this" {
  name        = "rds-mysql-subnets"
  subnet_ids  = var.private_subnet_ids
  description = "Subnet group for MySQL RDS"
}

resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}"
}

locals {
  final_password = try(var.db_config.password, null) != null && trim(var.db_config.password) != "" ? var.db_config.password : random_password.db.result
}

resource "aws_db_instance" "mysql" {
  identifier                  = "mysql-${var.db_config.db_name}"  
  engine                      = var.db_config.engine
  engine_version              = var.db_config.engine_version
  instance_class              = var.db_config.instance_class
  allocated_storage           = var.db_config.allocated_storage
  max_allocated_storage       = var.db_config.max_allocated_storage
  storage_type                = var.db_config.storage_type
  multi_az                    = var.db_config.multi_az

  db_name                     = var.db_config.db_name
  username                    = var.db_config.username
  password                    = local.final_password
  port                        = var.db_config.port

  publicly_accessible         = var.db_config.publicly_accessible
  deletion_protection         = var.db_config.deletion_protection

  backup_retention_period     = var.db_config.backup_retention_period
  backup_window               = var.db_config.backup_window
  maintenance_window          = var.db_config.maintenance_window
  auto_minor_version_upgrade  = var.db_config.auto_minor_version_upgrade
  performance_insights_enabled = var.db_config.performance_insights_enabled

  storage_encrypted           = true
  kms_key_id                  = try(var.db_config.kms_key_id, null)

  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [var.security_group_id]

  copy_tags_to_snapshot       = true
  apply_immediately           = false

  skip_final_snapshot         = var.db_config.skip_final_snapshot
}
