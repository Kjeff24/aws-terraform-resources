output "rds_instance_arn" {
  value = aws_db_instance.web_scenario_db.arn
  description = "ARN of the RDS instance"
}

output "rds_instance_id" {
  value = aws_db_instance.web_scenario_db.id
  description = "RDS instance ID"
}

output "rds_instance_endpoint" {
  value = aws_db_instance.web_scenario_db.address
  description = "RDS instance endpoint"
}


output "db_name" {
  value = aws_db_instance.web_scenario_db.db_name
  description = "Database name"
}

output "db_secret_arn" {
  value       = try(aws_db_instance.web_scenario_db.master_user_secret[0].secret_arn, "")
  description = "ARN of the Secrets Manager secret for the database credentials"
}