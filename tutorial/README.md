# ASM Terraform Tutorial

> Tested and supported only in Google Cloud Shell.

1.  Create a WORKDIR for this tutorial.

    ```bash
    mkdir asm-terraform-tutorial
    cd asm-terraform-tutorial
    export WORKDIR=$(pwd)
    ```

1.  Define variables.

    ```bash
    export PROJECT_ID=YOUR PROJECT ID
    export REPO_URL=REPO URL
    export VPC="vpc"
    export GKE1="gke1"
    export GKE2="gke2"
    export REGION="us-central1"
    export GKE1_LOCATION="${REGION}-a"
    export GKE2_LOCATION="${REGION}-b"
    export GKE1_KUBECONFIG="${WORKDIR}/gke1_kubeconfig"
    export GKE2_KUBECONFIG="${WORKDIR}/gke2_kubeconfig"
    ```

1.  Enabled required services.

    ```bash
    gcloud config set project "${PROJECT_ID}"

    gcloud --project="${PROJECT_ID}" services enable \
    container.googleapis.com \
    compute.googleapis.com \
    gkehub.googleapis.com \
    cloudresourcemanager.googleapis.com
    ```

1.  Set up Terraform authentication. Learn more about [GCP terraform authentication here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).

    ```bash
    gcloud auth application-default login --no-launch-browser
    ```

1.  Clone the repo.

    ```bash
    git clone "${REPO_URL}" asm-terraform
    cd asm-terraform
    ```

1.  Prepare VPC and GKE terraform module.

    ```bash
    cd vpc-gke
    envsubst < variables.tf.tmpl > variables.tf
    envsubst < provider.tf.tmpl > provider.tf
    ```

1.  Deploy VPC and GKE terraform module. This module also exports the kubeconfig using the [gke_auth](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/auth) module for the two GKE clusters as `local_file` resources. These kubeconfig files are used in the ASM module later.

    ```bash
    terraform init
    terraform plan
    terraform apply --auto-approve
    ```

1.  Register the clusters to Anthos Hub and enable the mesh feature.

    ```bash
    cd ../hub-mesh
    envsubst < variables.tf.tmpl > variables.tf
    envsubst < provider.tf.tmpl > provider.tf

    terraform init
    terraform plan
    terraform apply --auto-approve
    ```

1.  Verify that you have the ControlPlaneRevision CRD in both GKE clusters.

    ```bash
    gcloud --project=${PROJECT_ID} container clusters get-credentials ${GKE1} --zone ${GKE1_LOCATION}
    kubectl  wait --for=condition=established crd controlplanerevisions.mesh.cloud.google.com --timeout=5m

    gcloud --project=${PROJECT_ID} container clusters get-credentials ${GKE2} --zone ${GKE2_LOCATION}
    kubectl  wait --for=condition=established crd controlplanerevisions.mesh.cloud.google.com --timeout=5m
    ```

    Output is similar to the following.

    ```
    customresourcedefinition.apiextensions.k8s.io/controlplanerevisions.mesh.cloud.google.com condition met
    ```

1.  Install ASM on the GKE clusters.

    ```bash
    cd ../asm
    envsubst < variables.tf.tmpl > variables.tf
    envsubst < provider.tf.tmpl > provider.tf

    terraform init
    terraform plan
    terraform apply --auto-approve
    ```

1.  Configure multicluster mesh.

    ```bash

    ```

1.  Deploy a sample application on the GKE cluster.

    ```bash

    ```

1.  Verify mutlicluster mesh service discovery and routing.

    ```bash

    ```

1.  Inspect Service dashboards.
