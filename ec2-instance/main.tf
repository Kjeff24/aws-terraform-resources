
############################
# Key Pair Module
############################
module "keypair" {
  source       = "./modules/keypair"
  project_name = var.project_name
}

############################
# Security Groups Module
############################
module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
}

############################
# EC2 Instance Module
############################
module "ec2" {
  source = "./modules/ec2"
  instance_config = merge(
    var.instance_config,
    {
      key_name = length(trimspace(var.instance_config.key_name)) > 0 ? var.instance_config.key_name : module.keypair.key_pair_name
    }
  )
  security_group_id = module.security_groups.ec2_sg_id
}
