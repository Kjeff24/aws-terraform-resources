module "vpc" {
  source     = "./modules/vpc"
  networking = var.networking
}

module "security_groups" {
  source   = "./modules/security_groups"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.networking.vpc_cidr
}

module "rds" {
  source             = "./modules/rds"
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.security_group_id
  db_config          = var.db_config
}

