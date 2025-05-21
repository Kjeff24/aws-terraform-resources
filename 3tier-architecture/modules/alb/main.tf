/**
  Application Load Balancer for the web layer.
  - Public ALB across provided public subnets with cross-zone LB enabled
  - HTTP listener forwarding to target group
  - Target group on app_port with health check at /api/health

  Inputs: project_name, vpc_id, public_subnet_ids, alb_public_sg_id, app_port, tags
  Outputs: external_alb_target_arn (used by ASG attachment)
*/

## APPLICATION LOAD BALANCER
resource "aws_lb" "public_alb" {
  name                             = "${var.project_name}-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [var.alb_public_sg_id]
  subnets                          = var.public_subnet_ids
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name         = "Public ALB Web Layer"
    ResourceName = "Public-ALB"
  }
}

###################
## PUBLIC ALB LISTENER
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = var.alb_settings.listener_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tgroup.arn
  }
}


######################
## PUBLIC TARGET GROUP
resource "aws_lb_target_group" "public_tgroup" {
  name        = "${var.project_name}-alb-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = var.alb_settings.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = var.alb_settings.healthy_threshold
    unhealthy_threshold = var.alb_settings.unhealthy_threshold
    timeout             = var.alb_settings.timeout
    interval            = var.alb_settings.interval
  }

  tags = {
    Name         = "ABL attatch web tier"
    ResourceName = "Web-ALB-TG"
  }
}
