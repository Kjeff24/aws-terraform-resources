## Optionally generate an SSH key pair using the TLS provider
# Controlled by keypair_config.generate_key_pair and algorithm settings
resource "tls_private_key" "generated" {
  count     = (var.keypair_config.enabled && var.keypair_config.generate_key_pair) ? 1 : 0
  algorithm = var.keypair_config.key_algorithm

  rsa_bits    = var.keypair_config.key_algorithm == "RSA"   ? var.keypair_config.rsa_bits    : null
  ecdsa_curve = var.keypair_config.key_algorithm == "ECDSA" ? var.keypair_config.ecdsa_curve : null
}

## Optionally save the generated private key to a local file (0600 perms)
resource "local_file" "private_key" {
  count           = (var.keypair_config.enabled && var.keypair_config.generate_key_pair && var.keypair_config.save_private_key_path != "") ? 1 : 0
  filename        = var.keypair_config.save_private_key_path
  content         = tls_private_key.generated[0].private_key_pem
  file_permission = "0600"
}

## Optionally save the public key (generated or provided) to a local file
resource "local_file" "public_key" {
  count           = (var.keypair_config.enabled && var.keypair_config.save_public_key_path != "") ? 1 : 0
  filename        = var.keypair_config.save_public_key_path
  content         = var.keypair_config.generate_key_pair ? tls_private_key.generated[0].public_key_openssh : local.computed_public_key
  file_permission = "0644"
}

## Create the AWS EC2 Key Pair from the computed public key
# Reference this key from instances via aws_instance.key_name
resource "aws_key_pair" "this" {
  count      = var.keypair_config.enabled ? 1 : 0
  key_name   = var.keypair_config.key_pair_name
  public_key = local.computed_public_key

  tags = var.tags
}
