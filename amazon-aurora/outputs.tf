output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = module.aurora.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = module.aurora.cluster_reader_endpoint
}

output "cluster_port" {
  description = "Port the Aurora cluster listens on"
  value       = module.aurora.cluster_port
}

output "database_name" {
  description = "Name of the default database"
  value       = module.aurora.database_name
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master user password"
  value       = module.aurora.master_user_secret_arn
}
