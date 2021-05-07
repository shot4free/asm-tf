data "google_client_config" "default" {}

provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

data "google_project" "project" {
  project_id = var.project_id
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.0"

  project_id   = var.project_id
  network_name = var.network
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = var.subnetwork_ip_range
      subnet_region = var.region
    }
  ]

  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = var.ip_range_pods
        ip_cidr_range = var.ip_range_pods_cidr
      },
      {
        range_name    = var.ip_range_services
        ip_cidr_range = var.ip_range_services_cidr
      }
    ]
  }
}


module "gke" {
  source                  = "terraform-google-modules/kubernetes-engine/google"
  project_id              = var.project_id
  name                    = var.cluster_name
  regional                = false
  region                  = var.region
  zones                   = var.zones
  release_channel         = "REGULAR"
  network                 = module.vpc.network_name
  subnetwork              = module.vpc.subnets_names[0]
  ip_range_pods           = var.ip_range_pods
  ip_range_services       = var.ip_range_services
  network_policy          = false
  identity_namespace      = "enabled"
  cluster_resource_labels = { "mesh_id" : "proj-${data.google_project.project.number}" }
  node_pools = [
    {
      name         = "asm-node-pool"
      autoscaling  = false
      auto_upgrade = true
      # ASM requires minimum 4 nodes and e2-standard-4
      node_count   = 2
      machine_type = "e2-standard-4"
    },
  ]
}

module "asm" {
  source                = "github.com/ameer00/terraform-google-kubernetes-engine//modules/asm"
  cluster_name          = module.gke.name
  cluster_endpoint      = module.gke.endpoint
  project_id            = var.project_id
  location              = module.gke.location
  enable_all            = false
  enable_cluster_roles  = true
  enable_cluster_labels = false
  enable_gcp_apis       = false
  enable_gcp_iam_roles  = true
  enable_gcp_components = true
  enable_registration   = false
  asm_version           = "1.9"
  managed_control_plane = false
  options               = ["envoy-access-log,egressgateways"]
  custom_overlays       = ["./custom_ingress_gateway.yaml"]
  skip_validation       = true
  outdir                = "./${module.gke.name}-outdir-${var.asm_version}"
  # ca                    = "citadel"
  # ca_certs = {
  #   "ca_cert"    = "./ca-cert.pem"
  #   "ca_key"     = "./ca-key.pem"
  #   "root_cert"  = "./root-cert.pem"
  #   "cert_chain" = "./cert-chain.pem"
  # }
}
