/*
Terraform script to create a private Auto Scaling Group with EC2 instances.
Selects either a provided AMI or the latest Ubuntu 22.04 LTS.
Configures a launch template, IAM instance profile, private networking, user data,
scaling policies, and attaches the ASG to a public ALB target group.
*/

# Validate existence if provided
data "aws_ami" "validate" {
  count  = var.ec2_settings.ami_id != "" ? 1 : 0
  owners = ["self", "amazon", "099720109477"]

  filter {
    name   = "image-id"
    values = [var.ec2_settings.ami_id]
  }
}

# Default to latest Ubuntu
data "aws_ami" "ubuntu_latest" {
  count       = var.ec2_settings.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  selected_ami = var.ec2_settings.ami_id != "" ? data.aws_ami.validate[0].id : data.aws_ami.ubuntu_latest[0].id
}

########### PRIVATE ASG TEMPLATES ###
resource "aws_launch_template" "private_asg_template" {
  name_prefix   = "private_launch_template"
  image_id      = local.selected_ami
  instance_type = "t3.micro"

  # Add IAM instance profile for Session Manager
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
    instance_metadata_tags      = "enabled"
  }

  # Explicitly disable public IP assignment for private instances
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_private_sg_id]
    delete_on_termination       = true
  }

  user_data = base64encode(var.user_data)

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    ResourceName   = "Private-ASG-Instance"
    SessionManager = "Enabled"
    UserDataHash   = md5(var.user_data)
  }
}

## PRIVATE ASG CONFIGURATION
resource "aws_autoscaling_group" "private_asg" {
  vpc_zone_identifier       = var.private_subnet_ids
  min_size                  = var.ec2_settings.min_size
  max_size                  = var.ec2_settings.max_size
  desired_capacity          = var.ec2_settings.desired_capacity
  health_check_grace_period = var.ec2_settings.health_check_grace_period
  health_check_type         = "ELB"

  tag {
    key                 = "Name"
    value               = "Private-ASG-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "ResourceName"
    value               = "Private-ASG-Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "SessionManager"
    value               = "Enabled"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "AWS-Startup-Packages"
    propagate_at_launch = true
  }


  launch_template {
    id      = aws_launch_template.private_asg_template.id
    version = aws_launch_template.private_asg_template.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }

    triggers = ["launch_template"]
  }

}

## ASG SCALING POLICIES
resource "aws_autoscaling_policy" "private_scale_ec2_policy" {
  name                   = "PrivateScaleEc2"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.private_asg.name
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "private_reduce_ec2_policy" {
  name                   = "PrivateReduceEc2Scaling"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.private_asg.name
  policy_type            = "SimpleScaling"
}


## ASG Attachment to ALB Target Group
resource "aws_autoscaling_attachment" "web_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.private_asg.id
  lb_target_group_arn    = var.alb_target_arn
}

