############################
# RDS / Database Configuration (moved to variables_db.tf)
############################
variable "db_settings" {
  description = <<EOF
Comprehensive database configuration for the RDS instance used by the project.

This object groups all RDS-related settings (identifiers, credentials, engine/version,
instance sizing, storage, backups, maintenance windows, encryption and performance
insights). Validation rules are applied below to ensure values fall within supported
ranges and formats.

Notes:
- Treat `master_password` as sensitive; prefer supplying it via a secure secret
  backend (e.g. environment variables, Terraform Cloud workspace variables, or
  an external secret manager) rather than checking it into source control.
- Defaults are provided for a basic development configuration; adjust for
  production (larger instance class, storage, and retention policies).

Key attributes (summary):
  - database_identifier (string): RDS resource identifier (lowercase, hyphen allowed).
  - master_username (string): Admin username (must start with a letter, 3-31 chars).
  - master_password (string|null): Admin password or null to use other auth methods.
  - database_name (string): Logical DB name (letters, numbers, underscores).
  - database_port (number): TCP port (1-65535).
  - engine (string): One of: postgres, mysql, mariadb.
  - engine_version (string): Numeric version like '16.8' or '8.0'.
  - instance_class (string): EC2 instance family and size (e.g. db.t3.micro).
  - allocated_storage (number): Size in GB (20-16384).
  - multi_az_deployment (bool): High-availability flag.
  - backup_retention_period (number): Days to retain automated backups (0-35).
  - maintenance_window (string): e.g. 'sun:04:00-sun:05:00'.
  - skip_final_snapshot / deletion_protection (bool): Control teardown behaviour.
  - kms_key_id (string|null): KMS key ARN for encryption (or null/empty).

Example (development):
  db_settings = {
    database_identifier = "web_ec2_database"
    master_username     = "dbadmin"
    master_password     = "${var.some_secret_or_null}"
    database_name       = "web_scenario_db"
    database_port       = 5432
    engine              = "postgres"
    engine_version      = "16.8"
    instance_class      = "db.t3.micro"
    allocated_storage   = 20
    multi_az_deployment = true
    backup_retention_period = 7
    backup_window       = "03:00-04:00"
    maintenance_window  = "sun:04:00-sun:05:00"
    skip_final_snapshot = true
    deletion_protection = false
    kms_key_id          = null
  }
EOF
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

  default = {
    database_identifier                   = "web_ec2_database"
    master_username                       = "postgresUser"
    master_password                       = "postgresPass123"
    database_name                         = "web_scenario_db"
    database_port                         = 5432
    engine                                = "postgres"
    engine_version                        = "16.8"
    instance_class                        = "db.t3.micro"
    storage_type                          = "gp2"
    allocated_storage                     = 20
    multi_az_deployment                   = true
    backup_retention_period               = 7
    backup_window                         = "03:00-04:00"
    maintenance_window                    = "sun:04:00-sun:05:00"
    skip_final_snapshot                   = true
    deletion_protection                   = false
    kms_key_id                            = null
    performance_insights_enabled          = false
    performance_insights_kms_key_id       = null
    performance_insights_retention_period = 7
  }

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.db_settings.engine)
    error_message = "db_settings.engine must be one of: postgres, mysql, mariadb."
  }

  validation {
    condition     = var.db_settings.allocated_storage >= 20 && var.db_settings.allocated_storage <= 16384
    error_message = "db_settings.allocated_storage must be between 20 and 16384 (GB)."
  }

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.db_settings.storage_type)
    error_message = "db_settings.storage_type must be one of: gp2, gp3, io1, io2."
  }

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_settings.instance_class))
    error_message = "db_settings.instance_class must look like 'db.<family>.<size>' (e.g., db.t3.micro)."
  }

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{2,30}$", var.db_settings.master_username))
    error_message = "db_settings.username must start with a letter and be 3-31 chars long, containing only letters, numbers, or underscores."
  }

  validation {
    condition     = var.db_settings.database_port > 0 && var.db_settings.database_port <= 65535
    error_message = "Database port must be a valid TCP port between 1 and 65535."
  }

  validation {
    condition     = var.db_settings.backup_retention_period >= 0 && var.db_settings.backup_retention_period <= 35
    error_message = "db_settings.backup_retention_period must be between 0 and 35 days (RDS requirement)."
  }

  validation {
    condition = var.db_settings.master_password == null || (
      length(var.db_settings.master_password) >= 8 &&
      can(regex("[A-Z]", var.db_settings.master_password)) &&
      can(regex("[a-z]", var.db_settings.master_password)) &&
      can(regex("[0-9]", var.db_settings.master_password)) &&
      !can(regex("[/@\"'\\\\ ]", var.db_settings.master_password))
    )
    error_message = "db_settings.master_password must be null or at least 8 characters long, include upper/lowercase letters and a digit, and cannot contain / @ \" ' \\ or space."
  }


  validation {
    condition     = can(regex("^[a-z]{3}:[0-2][0-9]:[0-5][0-9]-[a-z]{3}:[0-2][0-9]:[0-5][0-9]$", var.db_settings.maintenance_window))
    error_message = "db_settings.maintenance_window must look like 'sun:04:00-sun:05:00' (three-letter day:HH:MM-day:HH:MM)."
  }

  validation {
    condition     = var.db_settings.kms_key_id == null || var.db_settings.kms_key_id == "" || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key\\/[0-9a-fA-F-]+$", var.db_settings.kms_key_id))
    error_message = "db_settings.kms_key_id must be a valid KMS key ARN (or null/empty)."
  }

  validation {
    condition     = !contains(["postgres", "admin", "root", "mysql", "oracle"], lower(var.db_settings.master_username))
    error_message = "db_settings.master_username must not be a reserved DB username like 'postgres', 'admin', 'root', 'mysql', or 'oracle'."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9_]+$", var.db_settings.database_name))
    error_message = "db_settings.name must contain only letters, numbers, or underscores."
  }

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)*$", var.db_settings.engine_version))
    error_message = "db_settings.engine_version must be a numeric version (e.g., '15.8' or '8.0')."
  }

  validation {
    condition     = can(regex("^[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", var.db_settings.database_identifier))
    error_message = "db_settings.database_identifier must be 1-63 characters, start with a lowercase letter, contain only lowercase letters, numbers, or hyphens, and must not end with a hyphen."
  }

  validation {
    condition     = var.db_settings.performance_insights_kms_key_id == null || var.db_settings.performance_insights_kms_key_id == "" || var.db_settings.performance_insights_enabled == true
    error_message = "When specifying performance_insights_kms_key_id, performance_insights_enabled must be true."
  }

  validation {
    condition     = var.db_settings.performance_insights_enabled == true || var.db_settings.performance_insights_retention_period == null
    error_message = "If 'performance_insights_retention_period' is set, 'performance_insights_enabled' must be true. Otherwise, it must be null."
  }

  validation {
    condition     = var.db_settings.performance_insights_retention_period == null || contains([7, 731], var.db_settings.performance_insights_retention_period) || (var.db_settings.performance_insights_retention_period % 31 == 0)
    error_message = "performance_insights_retention_period must be 7, 731, or a multiple of 31 days."
  }

  validation {
    condition     = var.db_settings.performance_insights_kms_key_id == null || var.db_settings.performance_insights_kms_key_id == "" || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key\\/[0-9a-fA-F-]+$", var.db_settings.performance_insights_kms_key_id))
    error_message = "performance_insights_kms_key_id must be a valid KMS key ARN (or null/empty)."
  }

}
