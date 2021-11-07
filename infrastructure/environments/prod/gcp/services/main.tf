module "services" {
  source     = "../../../../modules/gcp/services/"
  project_id = var.project_id
}
