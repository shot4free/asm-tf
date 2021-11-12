provider "kubernetes" {
  config_path = var.gke1_kubeconfig
  alias       = "gke1"
}
provider "kubernetes" {
  config_path = var.gke2_kubeconfig
  alias       = "gke2"
}

module "asm-ingressgateway-gke1" {
  source = "./module/"
  providers = {
    kubernetes = kubernetes.gke1
  }
  asm_gateways_namespace = var.asm_gateways_namespace
  asm_label              = var.asm_label
}

module "asm-ingressgateway-gke2" {
  source = "./module/"
  providers = {
    kubernetes = kubernetes.gke2
  }
  asm_gateways_namespace = var.asm_gateways_namespace
  asm_label              = var.asm_label
}

