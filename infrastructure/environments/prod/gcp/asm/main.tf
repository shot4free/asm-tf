locals {
  clusters = [
    {
      name       = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].name
      location   = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].location
      kubeconfig = "/workspace/gke-us-central1-0-kubeconfig"
    },
    {
      name       = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].name
      location   = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].location
      kubeconfig = "/workspace/gke-us-east4-0-kubeconfig"
    },
    {
      name       = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].name
      location   = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].location
      kubeconfig = "/workspace/gke-us-west2-0-kubeconfig"
    }
  ]
  clusters_kubeconfig_raw = {
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].name}" = module.asm-gke-us-central1-0.kubeconfig_raw
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].name}"    = module.asm-gke-us-east4-0.kubeconfig_raw
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].name}"    = module.asm-gke-us-west2-0.kubeconfig_raw
  }
  project_id = data.terraform_remote_state.prod_gcp_vpc.outputs.network.network.project
}

provider "kubernetes" {
  config_path = local.clusters[0].kubeconfig
  alias       = "gke-us-central1-0"
}
provider "kubernetes" {
  config_path = local.clusters[1].kubeconfig
  alias       = "gke-us-east4-0"
}

provider "kubernetes" {
  config_path = local.clusters[2].kubeconfig
  alias       = "gke-us-west2-0"
}

module "asm-gke-us-central1-0" {
  source = "../../../../modules/gcp/asm/"
  providers = {
    kubernetes = kubernetes.gke-us-central1-0
  }
  project_id   = local.project_id
  cluster_name = local.clusters[0].name
  location     = local.clusters[0].location
}

module "asm-gke-us-east4-0" {
  source = "../../../../modules/gcp/asm/"
  providers = {
    kubernetes = kubernetes.gke-us-east4-0
  }
  project_id   = local.project_id
  cluster_name = local.clusters[1].name
  location     = local.clusters[1].location
}

module "asm-gke-us-west2-0" {
  source = "../../../../modules/gcp/asm/"
  providers = {
    kubernetes = kubernetes.gke-us-west2-0
  }
  project_id   = local.project_id
  cluster_name = local.clusters[2].name
  location     = local.clusters[2].location
}

resource "kubernetes_secret" "gke-us-central1-0-kubeconfig-secrets" {
  for_each = { for cluster in local.clusters : cluster.name => cluster }
  provider = kubernetes.gke-us-central1-0
  metadata {
    name      = "${each.key}-secret-kubeconfig"
    namespace = module.asm-gke-us-central1-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = each.value.name
    }
  }
  data = {
    "${each.value.name}" = local.clusters_kubeconfig_raw[each.key]
  }
}

resource "kubernetes_secret" "gke-us-east4-0-kubeconfig-secrets" {
  for_each = { for cluster in local.clusters : cluster.name => cluster }
  provider = kubernetes.gke-us-east4-0
  metadata {
    name      = "${each.key}-secret-kubeconfig"
    namespace = module.asm-gke-us-east4-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = each.value.name
    }
  }
  data = {
    "${each.value.name}" = local.clusters_kubeconfig_raw[each.key]
  }
}

resource "kubernetes_secret" "gke-us-west2-0-kubeconfig-secrets" {
  for_each = { for cluster in local.clusters : cluster.name => cluster }
  provider = kubernetes.gke-us-west2-0
  metadata {
    name      = "${each.key}-secret-kubeconfig"
    namespace = module.asm-gke-us-west2-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = each.value.name
    }
  }
  data = {
    "${each.value.name}" = local.clusters_kubeconfig_raw[each.key]
  }
}
