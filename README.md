## ASM Terraform Module

1.  Set up.

    ```bash
    export PROJECT_ID=PROJECT_ID
    export REPO=THIS REPO URL

    gcloud config set project "${PROJECT_ID}"

    gcloud --project="${PROJECT_ID}" services enable \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com \
    container.googleapis.com \
    compute.googleapis.com \
    gkehub.googleapis.com \
    cloudresourcemanager.googleapis.com

    PROJECT_NUM=$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')
    TF_CLOUDBUILD_SA="${PROJECT_NUM}@cloudbuild.gserviceaccount.com"

    gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
        --member serviceAccount:"${TF_CLOUDBUILD_SA}" \
        --role roles/owner

    git clone ${REPO} asm-terraform
    cd asm-terraform

    gcloud builds submit --config cloudbuild.yaml
    ```
