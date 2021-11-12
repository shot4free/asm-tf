module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.0"

  project_id   = var.project_id
  network_name = var.vpc
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = var.subnet_name
      subnet_ip     = var.subnet_ip
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${var.subnet_name}" = [
      {
        range_name    = "${var.subnet_name}-pod-cidr"
        ip_cidr_range = var.pod_cidr
      },
      {
        range_name    = "${var.subnet_name}-svc1-cidr"
        ip_cidr_range = var.svc1_cidr
      },
      {
        range_name    = "${var.subnet_name}-svc2-cidr"
        ip_cidr_range = var.svc2_cidr
      },
    ]
  }

  firewall_rules = [{
    name        = "allow-all-10"
    description = "Allow Pod to Pod connectivity"
    direction   = "INGRESS"
    ranges      = ["10.0.0.0/8"]
    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
    }]
  }]
}

data "google_project" "project" {
  project_id = var.project_id
}

module "gke1" {
  source                    = "terraform-google-modules/kubernetes-engine/google"
  project_id                = module.vpc.project_id
  name                      = var.gke1
  regional                  = false
  region                    = var.region
  zones                     = [var.gke1_location]
  network                   = module.vpc.network_name
  subnetwork                = var.subnet_name
  ip_range_pods             = "${var.subnet_name}-pod-cidr"
  ip_range_services         = "${var.subnet_name}-svc1-cidr"
  default_max_pods_per_node = 64
  network_policy            = true
  cluster_resource_labels   = { "mesh_id" : "proj-${data.google_project.project.number}" }
  node_pools = [
    {
      name         = "node-pool-01"
      autoscaling  = true
      auto_upgrade = false
      min_count    = 1
      max_count    = 5
      node_count   = 2
      machine_type = "e2-standard-4"
    },
  ]
}

module "gke2" {
  source                    = "terraform-google-modules/kubernetes-engine/google"
  project_id                = module.vpc.project_id
  name                      = var.gke2
  regional                  = false
  region                    = var.region
  zones                     = [var.gke1_location]
  network                   = module.vpc.network_name
  subnetwork                = var.subnet_name
  ip_range_pods             = "${var.subnet_name}-pod-cidr"
  ip_range_services         = "${var.subnet_name}-svc2-cidr"
  default_max_pods_per_node = 64
  network_policy            = true
  cluster_resource_labels   = { "mesh_id" : "proj-${data.google_project.project.number}" }
  node_pools = [
    {
      name         = "node-pool-01"
      autoscaling  = true
      auto_upgrade = false
      min_count    = 1
      max_count    = 5
      node_count   = 2
      machine_type = "e2-standard-4"
    },
  ]
}

module "gke1_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id   = var.project_id
  cluster_name = module.gke1.name
  location     = module.gke1.location
}

module "gke2_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id   = var.project_id
  cluster_name = module.gke2.name
  location     = module.gke2.location
}

resource "local_file" "gke1_kubeconfig" {
  content  = module.gke1_auth.kubeconfig_raw
  filename = var.gke1_kubeconfig
}

resource "local_file" "gke2_kubeconfig" {
  content  = module.gke2_auth.kubeconfig_raw
  filename = var.gke2_kubeconfig
}
