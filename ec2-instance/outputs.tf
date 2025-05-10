# Security group outputs
output "ec2_sg_id" {
	value       = module.security_groups.ec2_sg_id
	description = "ID of the default EC2 security group created by the security_groups module"
}
output "key_pair_name" {
	value       = module.keypair.key_pair_name
	description = "Name of the created key pair"
}

output "key_pair_id" {
	value       = module.keypair.key_pair_id
	description = "Key pair resource ID"
}

output "key_fingerprint" {
	value       = module.keypair.key_fingerprint
	description = "MD5 public key fingerprint"
}

output "generated_private_key_pem" {
	value       = module.keypair.generated_private_key_pem
	description = "Generated private key PEM when generate_key_pair=true"
	sensitive   = true
}

output "generated_public_key_openssh" {
	value       = module.keypair.generated_public_key_openssh
	description = "Generated public key (OpenSSH) when generate_key_pair=true"
}

output "saved_private_key_path" {
	value       = module.keypair.saved_private_key_path
	description = "Path where the private key was saved (if configured)"
}

output "saved_public_key_path" {
	value       = module.keypair.saved_public_key_path
	description = "Path where the public key was saved (if configured)"
}

# EC2 instance outputs
output "instance_id" {
	value       = module.ec2.instance_id
	description = "ID of the EC2 instance"
}

output "public_ip" {
	value       = module.ec2.public_ip
	description = "Public IP address of the EC2 instance (if assigned)"
}

output "private_ip" {
	value       = module.ec2.private_ip
	description = "Private IP address of the EC2 instance"
}

output "public_dns" {
	value       = module.ec2.public_dns
	description = "Public DNS name of the EC2 instance (if assigned)"
}

output "availability_zone" {
	value       = module.ec2.availability_zone
	description = "Availability Zone where the EC2 instance is launched"
}
