module "vpc" {
  source       = "../../../../modules/gcp/vpc/"
  project_id   = var.project_id
  network_name = var.network_name
  subnets      = var.subnets
  fleets       = var.fleets
}
