output "clusters_local" { value = module.gke.clusters_local }
output "pets" { value = module.gke.pets }
output "clusters" {
  value     = module.gke
  sensitive = true
}
output "gke_auth" {
  value     = module.gke.gke_auth
  sensitive = true
}
