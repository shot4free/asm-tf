variable "project_id" {}

variable "cluster_name" {
  default = "gke-central"
}

variable "region" {
  default = "us-central1"
}

variable "zones" {
  default = ["us-central1-a"]
}

variable "network" {
  default = "asm-vpc"
}

variable "subnetwork" {
  default = "subnet-01"
}

variable "subnetwork_ip_range" {
  default = "10.10.10.0/24"
}

variable "ip_range_pods" {
  default = "subnet-01-pods"
}

variable "ip_range_pods_cidr" {
  default = "10.100.0.0/16"
}

variable "ip_range_services" {
  default = "subnet-01-services"
}

variable "ip_range_services_cidr" {
  default = "10.101.0.0/16"
}

variable "asm_version" {
  default = "1.9"
}
