data "google_container_cluster" "gke1" {
  name     = var.gke1
  location = var.gke1_location
}

data "google_container_cluster" "gke2" {
  name     = var.gke2
  location = var.gke2_location
}

provider "kubernetes" {
  config_path = var.gke1_kubeconfig
  alias       = "gke1"
}
provider "kubernetes" {
  config_path = var.gke2_kubeconfig
  alias       = "gke2"
}

module "asm-gke1" {
  source = "./module/"
  providers = {
    kubernetes = kubernetes.gke1
  }
  project_id   = var.project_id
  asm_channel  = var.asm_channel
  asm_label    = var.asm_label
  cluster_name = data.google_container_cluster.gke1.name
  location     = data.google_container_cluster.gke1.location
}

module "asm-gke2" {
  source = "./module/"
  providers = {
    kubernetes = kubernetes.gke2
  }
  project_id   = var.project_id
  asm_channel  = var.asm_channel
  asm_label    = var.asm_label
  cluster_name = data.google_container_cluster.gke2.name
  location     = data.google_container_cluster.gke2.location
}

resource "kubernetes_secret" "gke2_kubeconfig_secret_in_gke1" {
  provider = kubernetes.gke1
  metadata {
    name      = "${var.gke2}-secret-kubeconfig"
    namespace = module.asm-gke1.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = var.gke2
    }
  }
  data = {
    "${var.gke2}" = module.asm-gke2.kubeconfig_raw
  }
}

resource "kubernetes_secret" "gke1_kubeconfig_secret_in_gke2" {
  provider = kubernetes.gke2
  metadata {
    name      = "${var.gke1}-secret-kubeconfig"
    namespace = module.asm-gke2.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = var.gke1
    }
  }
  data = {
    "${var.gke1}" = module.asm-gke1.kubeconfig_raw
  }
}
