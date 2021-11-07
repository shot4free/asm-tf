module "gke" {
  source       = "../../../../modules/gcp/gke/"
  project_id   = var.project_id
  fleets       = var.fleets
  gke_config   = var.gke_config
  network_name = data.terraform_remote_state.prod_gcp_vpc.outputs.network_name
  subnets      = data.terraform_remote_state.prod_gcp_vpc.outputs.subnets
}
