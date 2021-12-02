variable "cluster_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_id" {
  type = string
}

variable "use_private_endpoint" {
  description = "Connect on the private GKE cluster endpoint"
  type        = bool
  default     = false
}

variable "asm_channel" {
  type = string
  default = "stable"
}

variable "cni_enabled" {
  description = "Needs to be true to run on GKE Autopilot clusters."
  type = bool
  default = true
}