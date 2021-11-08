# Kubeconfig files for Kubernetes provider
# variable "kubeconfig" {
#   type = object({
#     gke-us-central1-0-kubeconfig = string
#     gke-us-east4-0-kubeconfig    = string
#     gke-us-west2-0-kubeconfig    = string
#   })
#   default = {
# gke-us-central1-0-kubeconfig = "/workspace/gke-us-central1-0-kubeconfig"
# gke-us-east4-0-kubeconfig    = "/workspace/gke-us-east4-0-kubeconfig"
# gke-us-west2-0-kubeconfig    = "/workspace/gke-us-west2-0-kubeconfig"
#   }
# }

variable "cluster_name" {}
variable "project_id" {}
variable "location" {}
variable "use_private_endpoint" {
  description = "Connect on the private GKE cluster endpoint"
  type        = bool
  default     = false
}
