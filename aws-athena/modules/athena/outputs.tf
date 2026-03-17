output "workgroup_names" {
  description = "Map of Athena workgroup names (key: workgroup key, value: workgroup name)"
  value       = { for k, v in aws_athena_workgroup.workgroups : k => v.name }
}

output "workgroup_arns" {
  description = "Map of Athena workgroup ARNs (key: workgroup key, value: workgroup ARN)"
  value       = { for k, v in aws_athena_workgroup.workgroups : k => v.arn }
}

output "workgroup_ids" {
  description = "Map of Athena workgroup IDs (key: workgroup key, value: workgroup ID)"
  value       = { for k, v in aws_athena_workgroup.workgroups : k => v.id }
}
