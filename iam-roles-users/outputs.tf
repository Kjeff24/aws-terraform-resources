output "group_names" {
	description = "Names of IAM groups created"
	value       = module.iam.group_names
}

output "user_names" {
	description = "Names of IAM users created"
	value       = module.iam.user_names
}

output "role_names" {
	description = "Names of IAM roles created"
	value       = module.iam.role_names
}
