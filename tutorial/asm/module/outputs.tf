output "kubeconfig_raw" {
  sensitive   = true
  description = "A kubeconfig file configured to access the GKE cluster."
  value       = data.template_file.kubeconfig.rendered
}

output "asm_namespace" {
  value = kubernetes_namespace.ns-istio-system.metadata[0].name
}

output "asm_label" {
  value = local.asm_label
}