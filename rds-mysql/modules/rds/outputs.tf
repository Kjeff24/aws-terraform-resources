output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.mysql.id
}

output "db_endpoint" {
  description = "RDS endpoint hostname"
  value       = aws_db_instance.mysql.address
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.mysql.port
}

output "db_username" {
  description = "Master username"
  value       = aws_db_instance.mysql.username
}

output "db_password" {
  description = "Master password used"
  value       = local.final_password
  sensitive   = true
}



output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}
