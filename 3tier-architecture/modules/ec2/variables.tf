
#############
## VARIABLES
#############
variable "vpc_id" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "app_private_sg_id" {
  description = "The ID of the security group associated with the private application layer (e.g., EC2 or ECS instances)."
  type        = string
}

variable "alb_target_arn" {
  description = "ARN for public ALB target group"
  type        = string
}


variable "iam_instance_profile" {
  description = "IAM instance profile name for Session Manager access"
  type        = string
}

variable "user_data" {
  description = "Rendered EC2 user data script"
  type        = string
}

variable "ec2_settings" {
  description = "Object containing EC2/ASG settings for this module."
  type = object({
    ami_id                    = string
    min_size                  = number
    max_size                  = number
    desired_capacity          = number
    health_check_grace_period = number
  })
}
