/*
Terraform configuration for provisioning an Amazon RDS instance with enhanced security and monitoring.
Includes:
- RDS engine version selection and parameter group customization
- Private subnet group for database placement
- IAM role for Enhanced Monitoring with CloudWatch
- Encrypted RDS instance (PostgreSQL/MySQL) with automatic password management via Secrets Manager
- IAM policy for controlled application access to database secrets
*/

data "aws_rds_engine_version" "selected" {
  engine  = var.db_settings.engine
  version = var.db_settings.engine_version
}

## RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "rds-subnets"
  subnet_ids = var.db_subnet_ids

  tags = {
    ResourceName = "RDS Subnet Group"
  }
}

## RDS's Parameter Group
resource "aws_db_parameter_group" "rds_db_pmg" {
  name   = "ps-gd-pg"
  family = data.aws_rds_engine_version.selected.parameter_group_family

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "statement_timeout"
    value        = "15000"
    apply_method = "immediate"
  }

  parameter {
    name         = "work_mem"
    value        = "4096"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instance
resource "aws_db_instance" "web_scenario_db" {
  allocated_storage = var.db_settings.allocated_storage
  storage_type      = var.db_settings.storage_type
  engine            = var.db_settings.engine
  engine_version    = var.db_settings.engine_version
  instance_class    = var.db_settings.instance_class

  identifier                  = var.db_settings.database_identifier
  username                    = var.db_settings.master_username
  db_name                     = var.db_settings.database_name
  port                        = var.db_settings.database_port
  password                    = var.db_settings.master_password != null ? var.db_settings.master_password : null
  manage_master_user_password = var.db_settings.master_password == null ? true : null

  vpc_security_group_ids = [var.db_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name

  backup_retention_period = var.db_settings.backup_retention_period
  backup_window           = var.db_settings.backup_window
  maintenance_window      = var.db_settings.maintenance_window

  deletion_protection       = var.db_settings.deletion_protection
  skip_final_snapshot       = var.db_settings.skip_final_snapshot
  final_snapshot_identifier = var.db_settings.skip_final_snapshot ? null : "${var.db_settings.database_name}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  monitoring_interval                   = 60
  monitoring_role_arn                   = var.rds_monitoring_role_arn
  performance_insights_enabled          = var.db_settings.performance_insights_enabled
  performance_insights_kms_key_id       = var.db_settings.performance_insights_enabled ? var.db_settings.performance_insights_kms_key_id : null
  performance_insights_retention_period = var.db_settings.performance_insights_enabled ? var.db_settings.performance_insights_retention_period : null

  storage_encrypted = var.db_settings.kms_key_id != null && var.db_settings.kms_key_id != ""
  kms_key_id        = var.db_settings.kms_key_id

  parameter_group_name = aws_db_parameter_group.rds_db_pmg.name
  multi_az             = var.db_settings.multi_az_deployment

  tags = {
    ResourceName = "RDS Instance"
  }
}
