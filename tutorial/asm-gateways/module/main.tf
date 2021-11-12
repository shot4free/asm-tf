resource "kubernetes_namespace" "ns-asm-gateways" {
  metadata {
    labels = {
      "istio.io/rev" = "${var.asm_label}"
    }
    name = var.asm_gateways_namespace
  }
}

resource "kubernetes_service" "asm_ingressgateway" {
  metadata {
    name      = "asm-ingressgateway"
    namespace = kubernetes_namespace.ns-asm-gateways.metadata[0].name
  }

  spec {
    port {
      name = "http"
      port = 80
    }

    port {
      name = "https"
      port = 443
    }

    selector = {
      asm = "ingressgateway"
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "asm_ingressgateway" {
  metadata {
    name      = "asm-ingressgateway"
    namespace = kubernetes_namespace.ns-asm-gateways.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        asm = "ingressgateway"
      }
    }

    template {
      metadata {
        labels = {
          asm = "ingressgateway"
        }

        annotations = {
          "inject.istio.io/templates" = "gateway"
        }
      }

      spec {
        container {
          name  = "istio-proxy"
          image = "auto"
        }
      }
    }
  }
}

resource "kubernetes_role" "asm_ingressgateway_sds" {
  metadata {
    name      = "asm-ingressgateway-sds"
    namespace = kubernetes_namespace.ns-asm-gateways.metadata[0].name
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["secrets"]
  }
}

resource "kubernetes_role_binding" "asm_ingressgateway_sds" {
  metadata {
    name      = "asm-ingressgateway-sds"
    namespace = kubernetes_namespace.ns-asm-gateways.metadata[0].name
  }

  subject {
    kind = "ServiceAccount"
    name = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.asm_ingressgateway_sds.metadata[0].name
  }
}
