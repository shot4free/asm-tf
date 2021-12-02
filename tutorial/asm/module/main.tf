locals {
   asm_label = var.asm_channel == "stable" ? "asm-managed-stable" : var.asm_channel == "rapid" ? "asm-managed-rapid" : "asm-managed"
}

module "project-services" {
  source = "terraform-google-modules/project-factory/google//modules/project_services"

  project_id = var.project_id

  activate_apis = [
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "meshca.googleapis.com",
    "meshtelemetry.googleapis.com",
    "meshconfig.googleapis.com",
    "iamcredentials.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "stackdriver.googleapis.com",
  ]
}


resource "kubernetes_namespace" "ns-istio-system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_manifest" "cpr-asm-revision" {
  manifest = {
    apiVersion = "mesh.cloud.google.com/v1beta1"
    kind       = "ControlPlaneRevision"

    metadata = {
      name      = local.asm_label
      namespace = kubernetes_namespace.ns-istio-system.metadata[0].name
      labels = {
      "app.kubernetes.io/created-by" = "terraform"
      "mesh.cloud.google.com/managed-cni-enabled" = var.cni_enabled
      }

    }

    spec = {
      type    = "managed_service"
      channel = var.asm_channel
    }
  }
  wait_for = {
    fields = {
      "status.conditions[1].type" = "ProvisioningFinished"
    }
  }
}
resource "kubernetes_service_account" "ksa-istio-reader-sa" {
  metadata {
    name      = "istio-reader-sa"
    namespace = kubernetes_namespace.ns-istio-system.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "clusterole-istio-reader-sa-clusterrole" {
  metadata {
    name = "istio-reader-sa-clusterrole"
    labels = {
      "app"     = "istio-reader"
      "release" = "istio"
    }
  }
  rule {
    api_groups = ["config.istio.io", "security.istio.io", "networking.istio.io", "authentication.istio.io", "apiextensions.k8s.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["endpoints", "pods", "services", "nodes", "replicationcontrollers", "namespaces", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["replicasets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
  rule {
    api_groups = ["authorization.k8s.io"]
    resources  = ["subjectaccessreviews"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "clusterolebinding-istio-reader-sa-clusterrolebinding" {
  metadata {
    name = "istio-reader-sa-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.clusterole-istio-reader-sa-clusterrole.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ksa-istio-reader-sa.metadata[0].name
    namespace = kubernetes_service_account.ksa-istio-reader-sa.metadata[0].namespace
  }
}

data "kubernetes_secret" "ksa-secret-istio-reader-sa" {
  metadata {
    name      = kubernetes_service_account.ksa-istio-reader-sa.default_secret_name
    namespace = kubernetes_service_account.ksa-istio-reader-sa.metadata[0].namespace
  }
}


locals {
  cluster_ca_certificate = data.google_container_cluster.gke_cluster.master_auth != null ? data.google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate : ""
  private_endpoint       = try(data.google_container_cluster.gke_cluster.private_cluster_config[0].private_endpoint, "")
  default_endpoint       = data.google_container_cluster.gke_cluster.endpoint != null ? data.google_container_cluster.gke_cluster.endpoint : ""
  endpoint               = var.use_private_endpoint == true ? local.private_endpoint : local.default_endpoint
  host                   = local.endpoint != "" ? "https://${local.endpoint}" : ""
  context                = data.google_container_cluster.gke_cluster.name != null ? data.google_container_cluster.gke_cluster.name : ""
  token                  = lookup(data.kubernetes_secret.ksa-secret-istio-reader-sa.data, "token")
}

data "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.location
  project  = var.project_id
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/templates/kubeconfig-template.yaml.tpl")

  vars = {
    context                = local.context
    cluster_ca_certificate = local.cluster_ca_certificate
    endpoint               = local.endpoint
    token                  = local.token
  }
}

# data "template_file" "kubeconfig-secret" {
#   template = file("${path.module}/templates/kubeconfig-secret-template.yaml.tpl")
#   vars = {
#     cluster    = var.cluster_name
#     kubeconfig = base64encode(data.template_file.kubeconfig.rendered)
#   }
# }
