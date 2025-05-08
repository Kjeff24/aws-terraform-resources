module "vpc" {
  source     = "./modules/vpc"
  networking = var.networking
}
