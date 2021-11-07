output "clusters_local" { value = local.gke_clusters }
output "pets" { value = resource.random_pet.gke }
output "clusters" {
  value     = module.gke
  sensitive = true
}
output "gke_auth" {
  value     = module.gke_auth
  sensitive = true
}
