output "glue_service_role_arn" {
  description = "ARN of the IAM role for Glue service"
  value       = aws_iam_role.glue_service_role.arn
}

output "glue_service_role_name" {
  description = "Name of the IAM role for Glue service"
  value       = aws_iam_role.glue_service_role.name
}

output "glue_logs_group_name" {
  description = "CloudWatch log group name for Glue"
  value       = aws_cloudwatch_log_group.glue_logs.name
}
