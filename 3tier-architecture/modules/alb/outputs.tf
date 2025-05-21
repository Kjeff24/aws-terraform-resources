output "alb_id" {
  description = "ID of the ALB"
  value       = aws_lb.public_alb.id
}

output "alb_target_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.public_tgroup.arn
}


output "alb_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.public_alb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.public_alb.arn
}

