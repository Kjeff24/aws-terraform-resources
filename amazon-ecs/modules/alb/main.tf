/*
Module: Application Load Balancer

Description:
- Provisions an internet-facing Application Load Balancer, an HTTP listener,
  and an IP-based target group used by the ECS Fargate service.

Creates:
- aws_lb.main
- aws_lb_target_group.main
- aws_lb_listener.http

Inputs:
- var.project_name (string)
- var.vpc_id (string)
- var.public_subnet_ids (list(string))
- var.alb_security_group_id (string)
- var.container_port (number)
- var.health_check_path (string)

Notes:
- Target type is "ip" to support Fargate awsvpc networking.
- Listener forwards all HTTP traffic on port 80 to the target group.
*/

# ⚖️ Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name         = "${var.project_name}-alb"
    ResourceName = "ALB"
  }
}

# 🎯 Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name         = "${var.project_name}-tg"
    ResourceName = "TargetGroup"
  }
}

# 🔊 ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
