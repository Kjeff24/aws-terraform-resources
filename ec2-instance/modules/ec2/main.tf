data "aws_ami" "validate" {
  count  = var.instance_config.ami_id != "" ? 1 : 0
  owners = ["self", "amazon", "099720109477"]

  filter {
    name   = "image-id"
    values = [var.instance_config.ami_id]
  }
}

# Default to latest Ubuntu
data "aws_ami" "ubuntu_latest" {
  count       = var.instance_config.ami_id == "" ? 1 : 0
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
  selected_ami = var.instance_config.ami_id != "" ? data.aws_ami.validate[0].id : data.aws_ami.ubuntu_latest[0].id
}

## EC2 instance with user_data bootstrap
resource "aws_instance" "this" {
  ami                    = local.selected_ami
  instance_type          = var.instance_config.instance_type
  subnet_id              = var.instance_config.subnet_id
  vpc_security_group_ids = var.instance_config.security_group_ids
  key_name               = var.instance_config.key_name

  associate_public_ip_address = var.instance_config.associate_public_ip
  iam_instance_profile        = var.instance_config.iam_instance_profile != "" ? var.instance_config.iam_instance_profile : null
  disable_api_termination     = var.instance_config.disable_api_termination

  user_data = templatefile("${path.root}/user_data.sh", {})

  root_block_device {
    volume_size = var.instance_config.root_volume_size_gb
    volume_type = var.instance_config.root_volume_type
    encrypted   = true
  }

  tags = { ResourceName = "ec2-instance" }

}

