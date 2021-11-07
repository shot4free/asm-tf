#!/usr/bin/env bash

echo -e "LOCATIONS is $LOCATIONS"
echo -e "CLUSTERS is $CLUSTERS"

# Setup variables
IFS=',' read -r -a CLUSTER_NAMES <<< "${CLUSTERS}"
IFS=',' read -r -a CLUSTER_LOCS <<< "${LOCATIONS}"

CONTEXTS=()

for i in "${!CLUSTER_NAMES[@]}"; do
  # Create kubeconfig context
  gcloud container clusters get-credentials "${CLUSTER_NAMES[$i]}" --zone "${CLUSTER_LOCS[$i]}" --project ${PROJECT}
  CONTEXTS+=("gke_${PROJECT}_${CLUSTER_LOCS[$i]}_${CLUSTER_NAMES[$i]}")
cat <<EOF > whereami-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: whereami
  labels:
    istio.io/rev: ${ASM_LABEL}
EOF
cat <<EOF > whereami-service.yaml
apiVersion: "v1"
kind: "Service"
metadata:
  name: "whereami"
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: http # adding for Istio
  selector:
    app: "whereami"
  type: "LoadBalancer"
EOF
    kubectl apply -f whereami-namespace.yaml
    kubectl -n whereami apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/kubernetes-engine-samples/master/whereami/k8s/ksa.yaml
    kubectl -n whereami apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/kubernetes-engine-samples/master/whereami/k8s/configmap.yaml
    kubectl -n whereami apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/kubernetes-engine-samples/master/whereami/k8s/deployment.yaml
    kubectl -n whereami apply -f whereami-service.yaml
    kubectl -n whereami apply -f https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml
    kubectl -n whereami wait --for=condition=available deployment whereami --timeout=5m
    kubectl -n whereami wait --for=condition=available deployment sleep --timeout=5m
done

for CLUSTER in "${CONTEXTS[@]}"
do
  echo -e "\e[1;92mTesting connectivity from $CLUSTER to all other clusters...\e[0m"
  for CLUSTER_ZONE in "${CLUSTER_LOCS[@]}"
  do
    echo -e "\e[92mTesting connectivity from $CLUSTER to $CLUSTER_ZONE...\e[0m"
    unset SLEEP_POD
    SLEEP_POD=`kubectl --context=${CLUSTER} -n whereami get pod -l app=sleep  -o jsonpath='{.items[0].metadata.name}'`
    echo -e "\e[92mSLEEP_POD is ${SLEEP_POD}\e[0m"
    NUM=0
    while [[ ! "${SLEEP_POD}" ]] && [[ "${NUM}" -lt 10 ]]
      do
        echo -e "Sleeping for 3 seconds and retrying..."
        echo -e "Retry number $NUM..."
        sleep 3 # Sleep for 3 seconds and retry
        SLEEP_POD=`kubectl --context=${CLUSTER} -n whereami get pod -l app=sleep  -o jsonpath='{.items[0].metadata.name}'`
        echo -e "\e[92mSLEEP_POD is ${SLEEP_POD}\e[0m"
        NUM=$((NUM + 1))
      done
    [[ ! "${SLEEP_POD}" ]] && break
    echo -e "\e[92mSLEEP_POD is ${SLEEP_POD}\e[0m"
    echo -e "\e[92mCLUSTER_ZONE is ${CLUSTER_ZONE}\e[0m"
    ZONE=location
    NUM=0
    while [[ "$ZONE" != "$CLUSTER_ZONE" ]] && [[ "${NUM}" -lt 100 ]]
    do
      ZONE=`kubectl --context=${CLUSTER} -n whereami exec -i -n whereami -c sleep $SLEEP_POD -- curl -s whereami.whereami:80 | jq -r '.zone'`
      echo -e "ZONE is $ZONE"
      NUM=$((NUM + 1))
      echo -e "NUM is $NUM"
      [[ "$ZONE" == "$CLUSTER_ZONE" ]] && echo -e "CLUSTER_ZONE is $CLUSTER_ZONE and ZONE is $ZONE!!"
    done
    echo -e "\e[96m$CLUSTER can access $CLUSTER_ZONE\e[0m"
    echo -e "\e[96m$CLUSTER can access $CLUSTER_ZONE\e[0m" >> cluster-access.txt
  done
  cat cluster-access.txt
  echo -e "\n"
done
