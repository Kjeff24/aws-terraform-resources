module "vpc" {
  source = "./modules/vpc"

  region               = var.region
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  container_port       = var.ecs_config.container_port
}

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
  container_port        = var.ecs_config.container_port
  health_check_path     = var.health_check_path
}

module "iam" {
  source = "./modules/iam"

  region       = var.region
  project_name = var.project_name
}

module "ecs" {
  source = "./modules/ecs"

  region             = var.region
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.vpc.ecs_security_group_id
  target_group_arn   = module.alb.target_group_arn
  execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  health_check_path  = var.health_check_path
  db_password        = var.db_password
  ecs_config         = var.ecs_config
}
