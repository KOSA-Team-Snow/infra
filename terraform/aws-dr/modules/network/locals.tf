locals {
  name_base = "kosa-project-team3-snow-${random_string.name_suffix.result}"

  subnet_cidrs = {
    public = ["10.20.0.0/24", "10.20.1.0/24"]
    app    = ["10.20.10.0/24", "10.20.11.0/24"]
    data   = ["10.20.20.0/24", "10.20.21.0/24"]
  }

  nat_gateway_count = var.dr_active ? 2 : 1
}
