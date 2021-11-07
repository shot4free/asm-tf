# Fleets
variable "fleets" {
  type = list(object({
    region       = string
    env          = string
    num_clusters = number
    subnet = object({
      name = string
      cidr = string
    })
  }))
  default = [
    {
      region       = "us-west2"
      env          = "prod"
      num_clusters = 10
      subnet = {
        name = "us-west2"
        cidr = "10.1.0.0/17"
      }
    },
    {
      region       = "us-central1"
      env          = "prod"
      num_clusters = 1
      subnet = {
        name = "us-central1"
        cidr = "10.2.0.0/17"
      }
    },
    {
      region       = "us-east4"
      env          = "prod"
      num_clusters = 1
      subnet = {
        name = "us-east4"
        cidr = "10.3.0.0/17"
      }
    }
  ]
}

# GKE Config (config cluster for ingress etc.)
variable "gke_config" {
  type = object({
    name    = string
    region  = string
    zone    = string
    env     = string
    network = string
    subnet = object({
      name               = string
      ip_range           = string
      ip_range_pods_name = string
      ip_range_pods      = string
      ip_range_svcs_name = string
      ip_range_svcs      = string
    })
  })
  default = {
    name    = "gke-config"
    region  = "us-central1"
    zone    = "us-central1-a"
    env     = "config"
    network = "vpc-prod"
    subnet = {
      name               = "us-central1-config"
      ip_range           = "10.10.0.0/20"
      ip_range_pods_name = "us-central1-config-pods"
      ip_range_pods      = "10.11.0.0/18"
      ip_range_svcs_name = "us-central1-config-svcs"
      ip_range_svcs      = "10.12.0.0/24"
    }
  }
}


# VPC
variable "network_name" {
  type = string
}

# Subnets, only for GKE module
variable "subnets" {}

# Kubeconfig files for Kubernetes provider
variable "kubeconfig" {
  type = object({
    gke-us-central1-0-kubeconfig = string
    gke-us-east4-0-kubeconfig    = string
    gke-us-west2-0-kubeconfig    = string
  })
  default = {
    gke-us-central1-0-kubeconfig = "/workspace/gke-us-central1-0-kubeconfig"
    gke-us-east4-0-kubeconfig    = "/workspace/gke-us-east4-0-kubeconfig"
    gke-us-west2-0-kubeconfig    = "/workspace/gke-us-west2-0-kubeconfig"
  }
}

# Project
variable "project_id" {
  type = string
}
