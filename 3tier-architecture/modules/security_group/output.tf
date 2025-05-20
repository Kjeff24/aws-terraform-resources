# ────────────────────────────────────────────────
# Application Load Balancer (Public Layer)
# ────────────────────────────────────────────────
output "alb_public_sg_id" {
  description = "The ID of the security group associated with the public-facing Application Load Balancer (ALB)."
  value       = aws_security_group.alb_sg.id
}

output "alb_public_sg_arn" {
  description = "The ARN of the security group associated with the public-facing Application Load Balancer (ALB)."
  value       = aws_security_group.alb_sg.arn
}

# ────────────────────────────────────────────────
# Application Layer (Private)
# ────────────────────────────────────────────────
output "app_private_sg_id" {
  description = "The ID of the security group associated with the private application layer (e.g., EC2 or ECS instances)."
  value       = aws_security_group.private_sg.id
}

output "app_private_sg_arn" {
  description = "The ARN of the security group associated with the private application layer (e.g., EC2 or ECS instances)."
  value       = aws_security_group.private_sg.arn
}

# ────────────────────────────────────────────────
# Database Layer
# ────────────────────────────────────────────────
output "db_sg_id" {
  description = "The ID of the security group assigned to the database layer (e.g., RDS instance)."
  value       = aws_security_group.db_sg.id
}

output "db_sg_arn" {
  description = "The ARN of the security group assigned to the database layer (e.g., RDS instance)."
  value       = aws_security_group.db_sg.arn
}
