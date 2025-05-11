output "group_names" {
  description = "Names of IAM groups created"
  value       = [for k, g in aws_iam_group.this : g.name]
}

output "user_names" {
  description = "Names of IAM users created"
  value       = [for k, u in aws_iam_user.this : u.name]
}

output "role_names" {
  description = "Names of IAM roles created"
  value       = [for k, r in aws_iam_role.this : r.name]
}
