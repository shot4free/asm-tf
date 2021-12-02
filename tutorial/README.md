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
    export GKE1_CTX=gke_${PROJECT_ID}_${GKE1_LOCATION}_${GKE1}
    export GKE2_CTX=gke_${PROJECT_ID}_${GKE2_LOCATION}_${GKE2}
    export REGION="us-central1"
    export GKE1_LOCATION="${REGION}-a"
    export GKE2_LOCATION="${REGION}-b"
    export GKE1_KUBECONFIG="${WORKDIR}/gke1_kubeconfig"
    export GKE2_KUBECONFIG="${WORKDIR}/gke2_kubeconfig"
    export GKE_CHANNEL="REGULAR"
    export ASM_CHANNEL="regular"
    export CNI_ENABLED="true"
    export ASM_GATEWAYS_NAMESPACE="asm-gateways"
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
    git clone "${REPO_URL}" ${WORKDIR}/asm-terraform
    cd ${WORKDIR}/asm-terraform
    git checkout aa/tutorial
    cd tutorial
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

1.  Install ASM on the GKE clusters. This module also configures multi-cluster mesh by configuring cross-cluster kubeconfig secrets.

    ```bash
    cd ../asm
    envsubst < variables.tf.tmpl > variables.tf
    envsubst < provider.tf.tmpl > provider.tf

    terraform init
    terraform plan
    terraform apply --auto-approve

    export ASM_LABEL=$(terraform output asm_label | tr -d '"')
    ```

1.  Ensure ASM provisioning finishes successfully.

    ```bash
    kubectl --context=${GKE1_CTX} wait --for=condition=ProvisioningFinished controlplanerevision ${ASM_LABEL} -n istio-system --timeout=10m
    kubectl --context=${GKE2_CTX} wait --for=condition=ProvisioningFinished controlplanerevision ${ASM_LABEL} -n istio-system --timeout=10m
    ```

    Output is similar to the following:

    ```
    controlplanerevision.mesh.cloud.google.com/asm-managed condition met
    ```

1.  Deploy ASM ingress gateways in both clusters.

    ```bash
    cd ../asm-gateways
    envsubst < variables.tf.tmpl > variables.tf
    envsubst < provider.tf.tmpl > provider.tf

    terraform init
    terraform plan
    terraform apply --auto-approve
    ```

1.  Confirm both ASM ingress gateways are Running.

    ```bash
    kubectl --context=${GKE1_CTX} -n ${ASM_GATEWAYS_NAMESPACE} wait --for=condition=available --timeout=5m deployment asm-ingressgateway
    kubectl --context=${GKE2_CTX} -n ${ASM_GATEWAYS_NAMESPACE} wait --for=condition=available --timeout=5m deployment asm-ingressgateway
    ```

    Output is similar to the following:

    ```
    deployment.apps/asm-ingressgateway condition met
    ```

1.  Deploy a sample application on both clusters. Create some deploymends on `gke1` cluster and others on `gke2` cluster to verify multi-cluster mesh.

    ```bash
    cat <<EOF > ${WORKDIR}/namespace-online-boutique.yaml

    apiVersion: v1
    kind: Namespace
    metadata:
      name: online-boutique
      labels:
        istio.io/rev: ${ASM_LABEL}
    EOF

    kubectl --context=${GKE1_CTX} apply -f ${WORKDIR}/namespace-online-boutique.yaml
    kubectl --context=${GKE2_CTX} apply -f ${WORKDIR}/namespace-online-boutique.yaml

    git clone https://github.com/GoogleCloudPlatform/microservices-demo.git ${WORKDIR}/online-boutique
    kubectl --context=${GKE1_CTX} -n online-boutique apply -f ${WORKDIR}/online-boutique/release/kubernetes-manifests.yaml
    kubectl --context=${GKE2_CTX} -n online-boutique apply -f ${WORKDIR}/online-boutique/release/kubernetes-manifests.yaml

    kubectl --context=${GKE1_CTX} -n online-boutique delete deployment adservice
    kubectl --context=${GKE1_CTX} -n online-boutique delete deployment cartservice
    kubectl --context=${GKE1_CTX} -n online-boutique delete deployment redis-cart
    kubectl --context=${GKE1_CTX} -n online-boutique delete deployment currencyservice
    kubectl --context=${GKE1_CTX} -n online-boutique delete deployment emailservice

    kubectl --context=${GKE2_CTX} -n online-boutique delete deployment paymentservice
    kubectl --context=${GKE2_CTX} -n online-boutique delete deployment productcatalogservice
    kubectl --context=${GKE2_CTX} -n online-boutique delete deployment shippingservice
    kubectl --context=${GKE2_CTX} -n online-boutique delete deployment checkoutservice
    kubectl --context=${GKE2_CTX} -n online-boutique delete deployment recommendationservice

    kubectl --context=${GKE1_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment frontend
    kubectl --context=${GKE1_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment paymentservice
    kubectl --context=${GKE1_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment productcatalogservice
    kubectl --context=${GKE1_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment shippingservice
    kubectl --context=${GKE1_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment recommendationservice
    kubectl --context=${GKE1_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment checkoutservice

    kubectl --context=${GKE2_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment frontend
    kubectl --context=${GKE2_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment adservice
    kubectl --context=${GKE2_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment cartservice
    kubectl --context=${GKE2_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment currencyservice
    kubectl --context=${GKE2_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment emailservice
    kubectl --context=${GKE2_CTX} -n online-boutique wait --for=condition=available --timeout=5m deployment redis-cart

    kubectl --context=${GKE1_CTX} -n online-boutique apply -f ${WORKDIR}/asm-terraform/tutorial/online-boutique/asm-manifests.yaml
    kubectl --context=${GKE2_CTX} -n online-boutique apply -f ${WORKDIR}/asm-terraform/tutorial/online-boutique/asm-manifests.yaml
    ```

1.  Access Online Boutique via the ASM ingress. Verify mutlicluster mesh service discovery and routing by accessing the Online Boutique application through the ASM ingress gateway. You can access the application through either IP address.

    ```bash
    export GKE1_ASM_INGRESS_IP=$(kubectl --context=${GKE1_CTX} --namespace ${ASM_GATEWAYS_NAMESPACE} get svc asm-ingressgateway -o jsonpath={.status.loadBalancer.ingress..ip})
    export GKE2_ASM_INGRESS_IP=$(kubectl --context=${GKE2_CTX} --namespace ${ASM_GATEWAYS_NAMESPACE} get svc asm-ingressgateway -o jsonpath={.status.loadBalancer.ingress..ip})

    echo -e "GKE1 ASM Ingressgateway IP is ${GKE1_ASM_INGRESS_IP}"
    echo -e "GKE2 ASM Ingressgateway IP is ${GKE2_ASM_INGRESS_IP}"
    ```

1.  Inspect Service dashboards by accessing the link below.

    ```bash
    echo -e "https://console.cloud.google.com/anthos/services?project=${PROJECT_ID}"
    ```
