#!/bin/bash

namespace=cert-manager

helm repo add jetstack https://charts.jetstack.io --force-update

kubectl create namespace $namespace
kubectl annotate namespace $namespace linkerd.io/inject=enabled

helm install \
  cert-manager jetstack/cert-manager \
  --namespace $namespace \
  --version v1.18.0 \
  --set crds.enabled=true

kubectl rollout status deployment -n $namespace cert-manager
kubectl rollout status deployment -n $namespace cert-manager-cainjector
kubectl rollout status deployment -n $namespace cert-manager-webhook

echo "Create the self signed certificate authority"
openssl genrsa -out root.key 4096
openssl req -x509 -new -nodes -key root.key -sha256 -days 3650 -out root.crt -subj "/CN=otel-ca"

kubectl create -n $namespace secret tls otel-ca-secret --cert=root.crt --key=root.key

kubectl apply -f resources/
