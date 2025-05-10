module "vpc" {
  source = "./modules/vpc"
  networking = var.networking
}

module "keypair" {
  source         = "./modules/keypair"
  keypair_config = var.key_pair_config
  tags           = var.tags
}

module "security_groups" {
  source             = "./modules/security_groups"
  project_name       = var.project_name
  vpc_id             = var.vpc_id
  vpc_cidr           = var.networking.vpc_cidr
  ssh_allowed_cidrs  = var.ssh_allowed_cidrs
  http_allowed_cidrs = var.http_allowed_cidrs
}

module "ec2" {
  source = "./modules/ec2"
  # If instance_config.key_name is empty, default to the key created/imported by the keypair module
  instance_config = merge(
    var.instance_config,
    {
      key_name           = length(trimspace(var.instance_config.key_name)) > 0 ? var.instance_config.key_name : (var.key_pair_config.enabled ? module.keypair.key_pair_name : var.key_pair_config.key_pair_name),
      security_group_ids = length(var.instance_config.security_group_ids) > 0 ? var.instance_config.security_group_ids : [module.security_groups.ec2_sg_id]
    }
  )
  tags = var.tags
}
