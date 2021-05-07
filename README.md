# Deploying GKE cluster and Anthos Service Mesh using Terraform

This tutorial shows how to install ASM 1.9 on a GKE cluster using the ASM terraform module.  

## Objective

+   Create a GKE cluster and install ASM 1.9 using GKE and ASM terraform module.
+   Deploy Online Boutique (sample app) on an ASM labeled `online-boutique` namespace.
+   Inspect ASM Service Ops dashboards.

## Documentation

This tutorial uses the following documents:

+   [ASM Terraform Module](https://github.com/ameer00/terraform-google-kubernetes-engine/tree/master/modules/asm)

## Setting up your environment

1.  Create envars.

    ```bash
    # Enter your project ID below
    export PROJECT_ID=YOUR PROJECT ID HERE

    # Copy paste the rest below
    gcloud config set project ${PROJECT_ID}
    export PROJECT_NUM=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')
    export CLUSTER_1=gke-central
    export CLUSTER_1_ZONE=us-central1-a
    export WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
    export MESH_ID="proj-${PROJECT_NUM}"
    export TERRAFORM_SA="terraform-sa"
    export ASM_MAJOR_VERSION=1.9
    export ASM_VERSION=1.9.3-asm.2
    export ASM_REV=asm-193-2
    export ASM_MCP_REV=asm-managed
    ```

1.  Install [krew](https://krew.sigs.k8s.io/) and plugins.

    ```bash
    (
    set -x; cd "$(mktemp -d)" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}" &&
    tar zxvf krew.tar.gz &&
    KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" &&
    $KREW install --manifest=krew.yaml --archive=krew.tar.gz &&
    $KREW update
    )
    echo -e "export PATH="${PATH}:${HOME}/.krew/bin"" >> ~/.bashrc && source ~/.bashrc

    kubectl krew install ctx ns neat
    ```

1.  Install `kpt`

    ```bash
    sudo apt-get update && sudo apt-get install -y google-cloud-sdk-kpt netcat
    ```

1.  Clone this repo.

    ```bash
    git clone https://gitlab.com/asm7/asm-terraform.git
    cd asm-terraform && export WORKDIR=`pwd`
    ```

1.  Create a KUBECONFIG file for this tutorial.

    ```bash
    touch asm-kubeconfig && export KUBECONFIG=`pwd`/asm-kubeconfig
    ```

## Enabling APIs

1.  Enable the required APIs

    ```bash
    gcloud services enable \
    --project=${PROJECT_ID} \
    container.googleapis.com \
    compute.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    cloudtrace.googleapis.com \
    meshca.googleapis.com \
    meshtelemetry.googleapis.com \
    meshconfig.googleapis.com \
    iamcredentials.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    multiclusteringress.googleapis.com \
    cloudresourcemanager.googleapis.com
    ```

## Preparing terraform

1.  Create a GCP Service account, give it `roles/owner` IAM role and get the Service Account credential JSON key for terraform.

    ```bash
    gcloud --project=${PROJECT_ID} iam service-accounts create ${TERRAFORM_SA} \
    --description="terraform-sa" \
    --display-name=${TERRAFORM_SA}

    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/owner

    gcloud iam service-accounts keys create ${TERRAFORM_SA}.json \
    --iam-account=${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com
    ```

1.  Set terraform credentials and project ID.

    ```bash
    export GOOGLE_APPLICATION_CREDENTIALS=`pwd`/${TERRAFORM_SA}.json
    export TF_VAR_project_id=${PROJECT_ID}
    ```

1.  Create a custom overlay file.

    ```bash
    cat <<EOF > ${WORKDIR}/custom_ingress_gateway.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      components:
        ingressGateways:
        - name: istio-ingressgateway
          enabled: true
          k8s:
            hpaSpec:
              maxReplicas: 10
              minReplicas: 2
    EOF
    ```

## Installing ASM

1.  Verify that the your current terraform version is version 0.13. If it is not version 0.13, you can download terraform ver 0.13 [here](https://releases.hashicorp.com/terraform/)

    ```bash
    wget https://releases.hashicorp.com/terraform/0.13.7/terraform_0.13.7_linux_amd64.zip
    unzip terraform_0.13.7_linux_amd64.zip
    rm -rf terraform_0.13.7_linux_amd64.zip
    export TERRAFORM_CMD="./terraform" # Path of your terraform binary
    ```

1.  Download the sample `main.tf` file.

    ```bash
    wget https://gitlab.com/-/snippets/2116054/raw/master/main.tf
    ```

1.  Initialize and apply.

    ```bash
    ${TERRAFORM_CMD} init
    ${TERRAFORM_CMD} plan
    ${TERRAFORM_CMD} apply -auto-approve
    ```

## Accessing the cluster

1.  Connect to the GKE cluster.

    ```bash
    gcloud container clusters get-credentials ${CLUSTER_1} --zone ${CLUSTER_1_ZONE}
    ```

Remember to unset your `KUBECONFIG` var at the end.  

1.  Rename cluster context for easy switching.

    ```bash
    kubectl ctx ${CLUSTER_1}=gke_${PROJECT_ID}_${CLUSTER_1_ZONE}_${CLUSTER_1}
    ```

1.  Confirm cluster context.

    ```bash
    kubectl ctx
    ```

The output is similar to the following:  

    gke-central

## Injection based gateways for managed control plane only

This section is only pertinent if you installed ASM with managed control plane. If you install ASM with an in-cluster control plane, you should already have a Gateway deployed. However, you can also deploy aditional gateways using this method even for an in-cluster control plane.  

1.  Create a namespace for ingress gateways.

    ```bash
    kubectl --context=${CLUSTER_1} create namespace asm-gateways
    kubectl --context=${CLUSTER_1} label namespace asm-gateways istio.io/rev=${ASM_MCP_REV}
    ```

1.  Create a basic istio-ingress gateway using the injection based method. This is required if using managed control plane and you need an istio-ingress gateway.

    ```bash
    cat <<EOF > istio-ingressgateway-injection.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: istio-ingressgateway
      namespace: asm-gateways
    spec:
      type: LoadBalancer
      selector:
        istio: ingressgateway
      ports:
      - port: 80
        name: http
      - port: 443
        name: https
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: istio-ingressgateway
      namespace: asm-gateways
    spec:
      selector:
        matchLabels:
          istio: ingressgateway
      template:
        metadata:
          annotations:
            # This is required to tell Anthos Service Mesh to inject the gateway with the
            # required configuration.
            inject.istio.io/templates: gateway
          labels:
            istio: ingressgateway
            istio.io/rev: asm-managed # This is required only if the namespace is not labeled.
        spec:
          containers:
          - name: istio-proxy
            image: auto # The image will automatically update each time the pod starts.
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: istio-ingressgateway-sds
      namespace: asm-gateways
    rules:
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["get", "watch", "list"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: istio-ingressgateway-sds
      namespace: asm-gateways
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: istio-ingressgateway-sds
    subjects:
    - kind: ServiceAccount
      name: default
    EOF

    kubectl --context=${CLUSTER_1} apply -f istio-ingressgateway-injection.yaml
    ```

The output is similar to the following:  

    service/istio-ingressgateway created
    deployment.apps/istio-ingressgateway created
    role.rbac.authorization.k8s.io/istio-ingressgateway-sds created
    rolebinding.rbac.authorization.k8s.io/istio-ingressgateway-sds created

1.  Verify the resources are created.

    ```bash
    kubectl --context=${CLUSTER_1} get pod,service -n asm-gateways
    ```

The output is similar to the following:  

    NAME                                        READY   STATUS    RESTARTS   AGE
    pod/istio-ingressgateway-857f6ffd86-59x8x   1/1     Running   0          63s

    NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
    service/istio-ingressgateway   LoadBalancer   10.101.184.118   104.197.18.53   80:32711/TCP,443:30587/TCP   63s

## Deploying Online boutique app

1.  Set the ASM revision variable.

    ```bash
    export ASM_REVISION=${ASM_REV}
    ```

1.  Deploy Online Boutique to the GKE cluster.

    ```bash
    kpt pkg get \
    https://github.com/GoogleCloudPlatform/microservices-demo.git/release \
    online-boutique

    kubectl --context=${CLUSTER_1} create namespace online-boutique
    kubectl --context=${CLUSTER_1} label namespace online-boutique istio.io/rev=${ASM_REVISION}

    kubectl --context=${CLUSTER_1} -n online-boutique apply -f online-boutique
    ```

1.  Wait until all Deployments are Ready.

    ```bash
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment adservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment checkoutservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment currencyservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment emailservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment frontend
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment paymentservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment productcatalogservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment shippingservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment cartservice
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment loadgenerator
    kubectl --context=${CLUSTER_1} -n online-boutique wait --for=condition=available --timeout=5m deployment recommendationservice
    ```

## Ingress gateway

1.  If using an injection based istio-ingress gateway in a different namespace than istio-system, get the IP address of the external load balancer.

    ```bash
    kubectl --context=${CLUSTER_1} -n asm-gateways get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    ```

1.  Access the application via `istio-ingressgateway` Service hostname.

    ```bash
    kubectl --context=${CLUSTER_1} -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    ```

## Destroying terraform

1.  Destroy terraform resources by running the following commands:

    ```bash
    ${TERRAFORM_CMD} destroy -auto-approve
    ```

    
