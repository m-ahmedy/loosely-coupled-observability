#!/bin/bash

namespace=ingress-nginx
version=v1.13.3
type=kind

kubectl create namespace $namespace
kubectl annotate namespace $namespace linkerd.io/inject=enabled

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/tags/controller-$version/deploy/static/provider/$type/deploy.yaml

kubectl rollout status deployment -n $namespace ingress-nginx-controller
