module "iam" {
	source = "./modules/iam"

	groups = var.groups
	users  = var.users
	roles  = var.roles
}
