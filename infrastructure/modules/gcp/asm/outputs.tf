# Outputs
output "kubeconfig_raw" {
  sensitive   = true
  description = "A kubeconfig file configured to access the GKE cluster."
  value       = data.template_file.kubeconfig.rendered
}

output "kubeconfig_secret_raw" {
  sensitive   = true
  description = "A kubeconfig file secret configured to access the GKE cluster."
  value       = data.template_file.kubeconfig-secret.rendered
}

output "asm_namespace" {
  value = kubernetes_namespace.ns-istio-system.metadata[0].name
}


