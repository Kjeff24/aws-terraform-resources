output "db_instance_id" {
	value       = module.rds.db_instance_id
	description = "RDS instance identifier"
}

output "db_endpoint" {
	value       = module.rds.db_endpoint
	description = "RDS endpoint hostname"
}

output "db_port" {
	value       = module.rds.db_port
	description = "RDS port"
}

output "db_username" {
	value       = module.rds.db_username
	description = "Master username"
}

output "db_password" {
	value       = module.rds.db_password
	description = "Master password (sensitive)"
	sensitive   = true
}

output "db_security_group_id" {
	value       = module.security_groups.security_group_id
	description = "DB security group ID"
}

output "db_subnet_group_name" {
	value       = module.rds.subnet_group_name
	description = "DB subnet group name"
}
