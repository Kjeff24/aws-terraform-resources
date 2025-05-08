output "vpc_id" {
	description = "ID of the VPC"
	value       = module.vpc.vpc_id
}

output "vpc_cidr" {
	description = "CIDR block of the VPC"
	value       = module.vpc.vpc_cidr
}

output "availability_zones" {
	description = "List of Availability Zones used for subnet placement"
	value       = module.vpc.availability_zones
}

output "public_subnet_ids" {
	description = "IDs of public subnets"
	value       = module.vpc.public_subnet_ids
}

output "public_subnet_cidrs" {
	description = "CIDR blocks of public subnets"
	value       = module.vpc.public_subnet_cidrs
}

output "private_subnet_ids" {
	description = "IDs of private subnets"
	value       = module.vpc.private_subnet_ids
}

output "private_subnet_cidrs" {
	description = "CIDR blocks of private subnets"
	value       = module.vpc.private_subnet_cidrs
}

output "internet_gateway_id" {
	description = "ID of the Internet Gateway attached to the VPC"
	value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
	description = "ID of the NAT Gateway used for private subnet egress"
	value       = module.vpc.nat_gateway_id
}

output "nat_eip_allocation_id" {
	description = "Allocation ID of the Elastic IP associated with the NAT Gateway"
	value       = module.vpc.nat_eip_allocation_id
}

output "nat_eip_public_ip" {
	description = "Public IP of the Elastic IP associated with the NAT Gateway"
	value       = module.vpc.nat_eip_public_ip
}

output "public_route_table_id" {
	description = "ID of the route table associated with public subnets"
	value       = module.vpc.public_route_table_id
}

output "private_route_table_id" {
	description = "ID of the route table associated with private subnets"
	value       = module.vpc.private_route_table_id
}

