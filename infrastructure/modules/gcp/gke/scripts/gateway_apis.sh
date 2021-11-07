#!/usr/bin/env bash

gcloud container clusters get-credentials ${CLUSTER} --zone ${LOCATION} --project ${PROJECT} 

kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v${VER}" \
| kubectl apply -f -
