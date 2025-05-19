output "vpc_id" {
	description = "ID of the VPC"
	value       = aws_vpc.main.id
}

output "vpc_cidr" {
	description = "CIDR block of the VPC"
	value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
	description = "List of Availability Zones used for subnet placement"
	value       = local.azs
}

output "public_subnet_ids" {
	description = "IDs of public subnets"
	value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
	description = "CIDR blocks of public subnets"
	value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
	description = "IDs of private subnets"
	value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
	description = "CIDR blocks of private subnets"
	value       = aws_subnet.private[*].cidr_block
}

output "internet_gateway_id" {
	description = "ID of the Internet Gateway attached to the VPC"
	value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
	description = "ID of the NAT Gateway used for private subnet egress"
	value       = aws_nat_gateway.main.id
}

output "nat_eip_allocation_id" {
	description = "Allocation ID of the Elastic IP associated with the NAT Gateway"
	value       = aws_eip.nat.id
}

output "nat_eip_public_ip" {
	description = "Public IP of the Elastic IP associated with the NAT Gateway"
	value       = aws_eip.nat.public_ip
}

output "public_route_table_id" {
	description = "ID of the route table associated with public subnets"
	value       = aws_route_table.public.id
}

output "private_route_table_id" {
	description = "ID of the route table associated with private subnets"
	value       = aws_route_table.private.id
}

