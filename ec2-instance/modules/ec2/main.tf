## EC2 instance with user_data bootstrap
resource "aws_instance" "this" {
	ami                    = var.instance_config.ami_id
	instance_type          = var.instance_config.instance_type
	subnet_id              = var.instance_config.subnet_id
	vpc_security_group_ids = var.instance_config.security_group_ids
	key_name               = var.instance_config.key_name

	associate_public_ip_address = var.instance_config.associate_public_ip
	iam_instance_profile        = var.instance_config.iam_instance_profile != "" ? var.instance_config.iam_instance_profile : null
	disable_api_termination     = var.instance_config.disable_api_termination

	user_data = templatefile("${path.module}/user_data.sh", {})

	root_block_device {
		volume_size = var.instance_config.root_volume_size_gb
		volume_type = var.instance_config.root_volume_type
		encrypted   = true
	}

	tags = merge(var.tags, {
		Name = "ec2-instance"
	})
}

