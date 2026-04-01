/*
Root: Amazon Aurora

Description:
- Wires together the vpc and aurora modules to provision a production-ready
  Aurora cluster in isolated private subnets.

Module call order:
  vpc  →  aurora  (depends on subnet IDs and security group ID)
*/

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  aurora_port          = var.aurora_config.engine == "aurora-mysql" ? 3306 : 5432
}
