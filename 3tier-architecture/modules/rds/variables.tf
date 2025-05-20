variable "db_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "db_sg_id" {
  type        = string
  description = "The ID of the security group assigned to the database layer (e.g., RDS instance)."
}

variable "rds_monitoring_role_arn" {
  type        = string
  description = "IAM role arn for RDS Enhanced Monitoring"
}

variable "db_settings" {
  description = "Database configuration settings for RDS instance"
  type = object({
    database_identifier                   = string
    master_username                       = string
    master_password                       = string
    database_name                         = string
    database_port                         = number
    engine                                = string
    engine_version                        = string
    instance_class                        = string
    storage_type                          = string
    allocated_storage                     = number
    multi_az_deployment                   = bool
    backup_retention_period               = number
    backup_window                         = string
    maintenance_window                    = string
    skip_final_snapshot                   = bool
    deletion_protection                   = bool
    kms_key_id                            = string
    performance_insights_enabled          = bool
    performance_insights_kms_key_id       = string
    performance_insights_retention_period = number
  })
}