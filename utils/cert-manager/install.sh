#!/bin/bash

namespace=cert-manager

helm repo add jetstack https://charts.jetstack.io --force-update

kubectl create namespace $namespace
kubectl annotate namespace $namespace linkerd.io/inject=enabled

helm install \
  cert-manager jetstack/cert-manager \
  --namespace $namespace \
  --create-namespace \
  --version v1.18.0 \
  --set crds.enabled=true
