output "rds_monitoring_role_arn" {
  description = "IAM role arn for RDS Enhanced Monitoring"
  value       = aws_iam_role.rds_monitoring_role.arn
}