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
  cluster_name = data.google_container_cluster.gke1.name
  location     = data.google_container_cluster.gke1.location
}

module "asm-gke2" {
  source = "./module/"
  providers = {
    kubernetes = kubernetes.gke2
  }
  project_id   = var.project_id
  cluster_name = data.google_container_cluster.gke2.name
  location     = data.google_container_cluster.gke2.location
}
