data "google_container_cluster" "gke1" {
  name     = var.gke1
  location = var.gke1_location
}

data "google_container_cluster" "gke2" {
  name     = var.gke2
  location = var.gke2_location
}

resource "google_gke_hub_membership" "gke1_membership" {
  membership_id = var.gke1
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.gke1.id}"
    }
  }
  provider = google-beta
}

resource "google_gke_hub_membership" "gke2_membership" {
  membership_id = var.gke2
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.gke2.id}"
    }
  }
  provider = google-beta
}

resource "null_resource" "exec_gke1_mesh" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "${path.module}/scripts/mesh.sh"
    environment = {
      CLUSTER    = data.google_container_cluster.gke1.name
      LOCATION   = data.google_container_cluster.gke1.location
      PROJECT    = var.project_id
      KUBECONFIG = var.gke1_kubeconfig_path
    }
  }
  triggers = {
    build_number = "${timestamp()}"
    script_sha1  = sha1(file("${path.module}/scripts/mesh.sh")),
  }
}

resource "null_resource" "exec_gke2_mesh" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "${path.module}/scripts/mesh.sh"
    environment = {
      CLUSTER    = data.google_container_cluster.gke2.name
      LOCATION   = data.google_container_cluster.gke2.location
      PROJECT    = var.project_id
      KUBECONFIG = var.gke2_kubeconfig_path
    }
  }
  triggers = {
    build_number = "${timestamp()}"
    script_sha1  = sha1(file("${path.module}/scripts/mesh.sh")),
  }
}
