
############################
# Security Group Outputs
############################
# Security group outputs
output "ec2_sg_id" {
	value       = module.security_groups.ec2_sg_id
	description = "ID of the default EC2 security group created by the security_groups module"
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
