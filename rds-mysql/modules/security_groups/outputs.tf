output "security_group_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.db.id
}

output "security_group_name" {
  description = "Security group name"
  value       = aws_security_group.db.name
}
