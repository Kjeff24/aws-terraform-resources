
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  filename        = "${path.module}/terraform_private_key.pem"
  content         = tls_private_key.key.private_key_pem
  file_permission = "0600"
}

resource "local_file" "public_key" {
  filename        = "${path.module}/terraform-key.pub"
  content         = tls_private_key.key.public_key_openssh
  file_permission = "0644"
}

resource "aws_key_pair" "this" {
  key_name   = var.keypair_config.key_pair_name
  public_key = tls_private_key.key.public_key_openssh

  tags = {
    ResourceName = "ec2-key-pair"
  }
}
