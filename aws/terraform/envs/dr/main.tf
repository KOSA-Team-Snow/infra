module "network" {
  source = "../../modules/network"

  region    = var.region
  dr_active = var.dr_active
  vpc_cidr  = var.vpc_cidr
  azs       = var.azs
}
