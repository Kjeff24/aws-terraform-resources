output "key_pair_name" {
  description = "Name of the created key pair"
  value       = var.keypair_config.enabled ? aws_key_pair.this[0].key_name : var.keypair_config.key_pair_name
}

output "key_pair_id" {
  description = "Key pair resource ID"
  value       = var.keypair_config.enabled ? aws_key_pair.this[0].id : null
}

output "key_fingerprint" {
  description = "MD5 public key fingerprint"
  value       = var.keypair_config.enabled ? aws_key_pair.this[0].fingerprint : null
}

output "generated_private_key_pem" {
  description = "Generated private key (PEM) when generate_key_pair=true"
  value       = (var.keypair_config.enabled && var.keypair_config.generate_key_pair) ? tls_private_key.generated[0].private_key_pem : null
  sensitive   = true
}

output "generated_public_key_openssh" {
  description = "Generated public key (OpenSSH) when generate_key_pair=true"
  value       = (var.keypair_config.enabled && var.keypair_config.generate_key_pair) ? tls_private_key.generated[0].public_key_openssh : null
}

output "saved_private_key_path" {
  description = "Path where the private key was written (if configured)"
  value       = var.keypair_config.save_private_key_path != "" ? var.keypair_config.save_private_key_path : null
}

output "saved_public_key_path" {
  description = "Path where the public key was written (if configured)"
  value       = var.keypair_config.save_public_key_path != "" ? var.keypair_config.save_public_key_path : null
}
