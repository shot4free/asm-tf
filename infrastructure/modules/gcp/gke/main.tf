data "google_compute_zones" "available" {
  for_each = toset([for fleet in var.fleets : fleet.region])
  project  = var.project_id
  region   = each.value
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "random_pet" "gke" {
  for_each = { for cluster in local.gke_clusters : cluster.cluster_num => cluster }
  keepers = {
    gke = each.key
  }
}

locals {
  # subnets = data.terraform_remote_state.prod_gcp_vpc.outputs.subnets
  subnets = var.subnets
  zones   = data.google_compute_zones.available
  gke_clusters = flatten([[
    for fleet in var.fleets : [
      for num in range(fleet.num_clusters) : {
        zone              = local.zones[fleet.region].names[num % length(local.zones[fleet.region].names)]
        env               = fleet.env
        region            = fleet.region
        subnetwork        = local.subnets["${fleet.region}/${fleet.region}"].name
        ip_range_pods     = "${fleet.region}-pod-cidr"
        ip_range_services = "${fleet.region}-svc-cidr-${num}"
        network           = var.network_name
        cluster_num       = "gke-${fleet.region}-${num}"
        name              = ""
      }
    ]
    ], [
    {
      zone              = var.gke_config.zone
      env               = var.gke_config.env
      region            = var.gke_config.region
      subnetwork        = var.gke_config.subnet.name
      ip_range_pods     = var.gke_config.subnet.ip_range_pods_name
      ip_range_services = var.gke_config.subnet.ip_range_svcs_name
      network           = var.network_name
      cluster_num       = var.gke_config.name
      name              = var.gke_config.name
    }
    ]
  ])
}

module "gke" {
  source                    = "terraform-google-modules/kubernetes-engine/google"
  for_each                  = { for cluster in local.gke_clusters : cluster.cluster_num => cluster }
  project_id                = var.project_id
  name                      = each.value.name != "" ? "${each.value.name}-${random_pet.gke[each.key].id}" : "gke-${each.value.zone}-${random_pet.gke[each.key].id}"
  regional                  = false
  region                    = each.value.region
  zones                     = [each.value.zone]
  release_channel           = "UNSPECIFIED"
  maintenance_start_time    = "08:00"
  network                   = each.value.network
  subnetwork                = each.value.subnetwork
  ip_range_pods             = each.value.ip_range_pods
  ip_range_services         = each.value.ip_range_services
  default_max_pods_per_node = 64
  network_policy            = true
  cluster_resource_labels   = { "mesh_id" : "proj-${data.google_project.project.number}", "env" : "${each.value.env}", "infra" : "gcp" }
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

module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  for_each     = { for cluster in local.gke_clusters : cluster.cluster_num => cluster }
  project_id   = var.project_id
  cluster_name = module.gke[each.key].name
  location     = module.gke[each.key].location
}

resource "local_file" "gke-us-central1-0-kubeconfig" {
  content  = module.gke_auth["gke-us-central1-0"].kubeconfig_raw
  filename = var.kubeconfig.gke-us-central1-0-kubeconfig
}

resource "local_file" "gke-us-east4-0-kubeconfig" {
  content  = module.gke_auth["gke-us-east4-0"].kubeconfig_raw
  filename = var.kubeconfig.gke-us-east4-0-kubeconfig
}

resource "local_file" "gke-us-west2-0-kubeconfig" {
  content  = module.gke_auth["gke-us-west2-0"].kubeconfig_raw
  filename = var.kubeconfig.gke-us-west2-0-kubeconfig
}

# resource "google_gke_hub_membership" "membership" {
#   for_each      = { for cluster in local.gke_clusters : cluster.cluster_num => cluster }
#   membership_id = each.key
#   endpoint {
#     gke_cluster {
#       resource_link = "//container.googleapis.com/${module.gke[each.key].cluster_id}"
#     }
#   }
#   provider   = google-beta
#   depends_on = [module.gke]
# }

# resource "null_resource" "exec_mesh" {
#   for_each = { for cluster in local.gke_clusters : cluster.cluster_num => cluster }
#   provisioner "local-exec" {
#     interpreter = ["bash", "-exc"]
#     command     = "${path.module}/scripts/mesh.sh"
#     environment = {
#       CLUSTER    = module.gke[each.key].name
#       LOCATION   = module.gke[each.key].location
#       PROJECT    = var.project_id
#       KUBECONFIG = "~/${module.gke[each.key].name}-kubeconfig"
#     }
#   }
#   triggers = {
#     build_number = "${timestamp()}"
#     script_sha1  = sha1(file("${path.module}/scripts/mesh.sh")),
#   }
#   depends_on = [module.gke]
# }
