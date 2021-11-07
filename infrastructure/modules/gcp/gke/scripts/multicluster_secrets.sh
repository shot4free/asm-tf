#!/usr/bin/env bash

echo -e "LOCATIONS is $LOCATIONS"
echo -e "CLUSTERS is $CLUSTERS"

# Setup variables
IFS=',' read -r -a CLUSTER_NAMES <<< "${CLUSTERS}"
IFS=',' read -r -a CLUSTER_LOCS <<< "${LOCATIONS}"

# export _MINOR=$(echo ${ASM_VERSION} | cut -d "." -f 2)
# export _POINT=$(echo ${ASM_VERSION} | cut -d "." -f 3 | cut -d "-" -f 1)
# export _REV=$(echo ${ASM_VERSION} | cut -d "-" -f 2 | cut -d "." -f 2)

# Download ASM installation package for istioctl bin
curl -LO https://storage.googleapis.com/gke-release/asm/istio-${ASM_VERSION}-linux-amd64.tar.gz
tar xzf istio-${ASM_VERSION}-linux-amd64.tar.gz
ISTIOCTL_CMD=$(pwd)/istio-${ASM_VERSION}/bin/istioctl

${ISTIOCTL_CMD} version

#### Set multicluster secrets
for i in "${!CLUSTER_NAMES[@]}"; do
  # Create kubeconfig context
  gcloud container clusters get-credentials "${CLUSTER_NAMES[$i]}" --zone "${CLUSTER_LOCS[$i]}" --project ${PROJECT}

  # Create secret manifests for each cluster
  echo -e "Creating kubeconfig secrets file for ${CLUSTER_NAMES[$i]}..."
  ${ISTIOCTL_CMD} x create-remote-secret --name="${CLUSTER_NAMES[$i]}" --log_output_level=all:none > "${CLUSTER_NAMES[$i]}"-kubeconfig-secret.yaml
  echo -e "Kubeconfig secrets file for ${CLUSTER_NAMES[$i]}:"
  cat "${CLUSTER_NAMES[$i]}"-kubeconfig-secret.yaml
done

for i in "${!CLUSTER_NAMES[@]}";
do
  for j in "${!CLUSTER_NAMES[@]}";
  do
    if [[ "${CLUSTER_NAMES[$j]}" != "${CLUSTER_NAMES[$i]}" ]]; then
      echo -e "Creating secret in ${CLUSTER_NAMES[$j]} for ${CLUSTER_NAMES[$i]}..."
      kubectl apply -f "${CLUSTER_NAMES[$j]}"-kubeconfig-secret.yaml --context=gke_"${PROJECT}"_"${CLUSTER_LOCS[$i]}"_"${CLUSTER_NAMES[$i]}"
    fi
  done
done