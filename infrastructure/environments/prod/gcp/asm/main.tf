locals {
  gke-us-central1-0-kubeconfig = "/workspace/gke-us-central1-0-kubeconfig"
  gke-us-east4-0-kubeconfig    = "/workspace/gke-us-east4-0-kubeconfig"
  gke-us-west2-0-kubeconfig    = "/workspace/gke-us-west2-0-kubeconfig"
  asm-namespace                = "istio-system"
}

provider "kubernetes" {
  config_path = local.gke-us-central1-0-kubeconfig
  alias       = "gke-us-central1-0"
}
provider "kubernetes" {
  config_path = local.gke-us-east4-0-kubeconfig
  alias       = "gke-us-east4-0"
}

provider "kubernetes" {
  config_path = local.gke-us-west2-0-kubeconfig
  alias       = "gke-us-west2-0"
}

module "asm-gke-us-central1-0" {
  source = "../../../../modules/gcp/asm/"
  providers = {
    kubernetes = kubernetes.gke-us-central1-0
  }
  project_id   = data.terraform_remote_state.prod_gcp_vpc.outputs.network.network.project
  cluster_id   = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].cluster_id
  cluster_name = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].name
  location     = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].location
}

module "asm-gke-us-east4-0" {
  source = "../../../../modules/gcp/asm/"
  providers = {
    kubernetes = kubernetes.gke-us-east4-0
  }
  project_id   = data.terraform_remote_state.prod_gcp_vpc.outputs.network.network.project
  cluster_id   = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].cluster_id
  cluster_name = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].name
  location     = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].location
}

module "asm-gke-us-west2-0" {
  source = "../../../../modules/gcp/asm/"
  providers = {
    kubernetes = kubernetes.gke-us-west2-0
  }
  project_id   = data.terraform_remote_state.prod_gcp_vpc.outputs.network.network.project
  cluster_id   = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].cluster_id
  cluster_name = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].name
  location     = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].location
}

resource "kubernetes_secret" "gke-us-central1-0-kubeconfig-secret-gke-us-east4-0" {
  provider = kubernetes.gke-us-central1-0
  metadata {
    name      = "gke-us-east4-0-secret-kubeconfig"
    namespace = module.asm-gke-us-central1-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].name
    }
  }
  data = {
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].name}" = module.asm-gke-us-east4-0.kubeconfig_raw
  }
}

resource "kubernetes_secret" "gke-us-central1-0-kubeconfig-secret-gke-us-west2-0" {
  provider = kubernetes.gke-us-central1-0
  metadata {
    name      = "gke-us-west2-0-secret-kubeconfig"
    namespace = module.asm-gke-us-central1-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].name
    }
  }
  data = {
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].name}" = module.asm-gke-us-west2-0.kubeconfig_raw
  }
}

resource "kubernetes_secret" "gke-us-east4-0-kubeconfig-secret-gke-us-central1-0" {
  provider = kubernetes.gke-us-east4-0
  metadata {
    name      = "gke-us-central1-0-secret-kubeconfig"
    namespace = module.asm-gke-us-east4-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].name
    }
  }
  data = {
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].name}" = module.asm-gke-us-central1-0.kubeconfig_raw
  }
}

resource "kubernetes_secret" "gke-us-east4-0-kubeconfig-secret-gke-us-west2-0" {
  provider = kubernetes.gke-us-east4-0
  metadata {
    name      = "gke-us-west2-0-secret-kubeconfig"
    namespace = module.asm-gke-us-east4-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].name
    }
  }
  data = {
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-west2-0"].name}" = module.asm-gke-us-west2-0.kubeconfig_raw
  }
}

resource "kubernetes_secret" "gke-us-west2-0-kubeconfig-secret-gke-us-central1-0" {
  provider = kubernetes.gke-us-west2-0
  metadata {
    name      = "gke-us-central1-0-secret-kubeconfig"
    namespace = module.asm-gke-us-west2-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].name
    }
  }
  data = {
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-central1-0"].name}" = module.asm-gke-us-central1-0.kubeconfig_raw
  }
}

resource "kubernetes_secret" "gke-us-west2-0-kubeconfig-secret-gke-us-east4-0" {
  provider = kubernetes.gke-us-west2-0
  metadata {
    name      = "gke-us-east4-0-secret-kubeconfig"
    namespace = module.asm-gke-us-west2-0.asm_namespace
    labels = {
      "istio/multiCluster" = "true"
    }
    annotations = {
      "networking.istio.io/cluster" = data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].name
    }
  }
  data = {
    "${data.terraform_remote_state.prod_gcp_gke.outputs.clusters.clusters["gke-us-east4-0"].name}" = module.asm-gke-us-east4-0.kubeconfig_raw
  }
}
