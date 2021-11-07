# Outputs
output "gke-us-central1-0-kubeconfig_raw" {
  sensitive = true
  value     = module.asm-gke-us-central1-0.kubeconfig_raw
}

output "gke-us-east4-0-kubeconfig_raw" {
  sensitive = true
  value     = module.asm-gke-us-east4-0.kubeconfig_raw
}

output "gke-us-west2-0-kubeconfig_raw" {
  sensitive = true
  value     = module.asm-gke-us-west2-0.kubeconfig_raw
}

output "gke-us-central1-0-kubeconfig_secret_raw" {
  sensitive = true
  value     = module.asm-gke-us-central1-0.kubeconfig_secret_raw
}

output "gke-us-east4-0-kubeconfig_secret_raw" {
  sensitive = true
  value     = module.asm-gke-us-east4-0.kubeconfig_secret_raw
}

output "gke-us-west2-0-kubeconfig_secret_raw" {
  sensitive = true
  value     = module.asm-gke-us-west2-0.kubeconfig_secret_raw
}
