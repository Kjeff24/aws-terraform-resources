variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (min 2 in different AZs)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID to associate with the RDS instance"
  type        = string
}

variable "db_config" {
  description = "RDS MySQL configuration"
  type = object({
    engine                     : string
    engine_version             : string
    instance_class             : string
    allocated_storage          : number
    max_allocated_storage      : number
    storage_type               : string
    multi_az                   : bool
    db_name                    : string
    username                   : string
    password                   : optional(string)
    port                       : number
    publicly_accessible        : bool
    deletion_protection        : bool
    backup_retention_period    : number
    backup_window              : string
    maintenance_window         : string
    performance_insights_enabled : bool
    kms_key_id                 : optional(string)
    auto_minor_version_upgrade : bool
    skip_final_snapshot        : bool
  })
}
