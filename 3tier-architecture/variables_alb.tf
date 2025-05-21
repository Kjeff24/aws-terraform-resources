############################
# Application Load Balancer Configuration (moved to variables_alb.tf)
############################
variable "alb_settings" {
  description = <<EOF
An object containing ALB-specific settings used by the module.

Attributes:
  - listener_port (number): Port the ALB listener will listen on (for example, 80 or 443).
  - health_check_path (string): Path used by the ALB target group to perform health checks (for example, "/api/health").
  - healthy_threshold (number): Number of consecutive successful health checks required before considering a target healthy.
  - unhealthy_threshold (number): Number of consecutive failed health checks required before considering a target unhealthy.
  - timeout (number): Amount of time (in seconds) to wait for a health check response before marking it failed.
  - interval (number): Interval (in seconds) between health checks.

Example:
  alb_settings = {
    listener_port        = 80
    health_check_path    = "/api/health"
    healthy_threshold    = 2
    unhealthy_threshold  = 2
    timeout              = 4
    interval             = 5
  }
EOF
  type = object({
    listener_port       = number
    health_check_path   = string
    healthy_threshold   = number
    unhealthy_threshold = number
    timeout             = number
    interval            = number
  })

  default = {
    listener_port       = 80
    health_check_path   = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 5
  }
}
