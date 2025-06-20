#!/bin/bash

port=8082
namespace=fluent-bit

kubectl create namespace $namespace
kubectl annotate namespace $namespace linkerd.io/inject=enabled

helm repo add fluent https://fluent.github.io/helm-charts --force-update

helm upgrade --install fluent-bit fluent/fluent-bit \
  --namespace $namespace --create-namespace \
  -f helm/fluent-bit.yaml

kubectl rollout status daemonset -n $namespace fluent-bit

kubectl port-forward -n $namespace svc/fluent-bit $port:2020 &

open http://localhost:$port
