#!/bin/bash

port=8443
namespace=kubernetes-dashboard

kubectl create namespace $namespace
kubectl annotate namespace $namespace linkerd.io/inject=enabled

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ --force-update

helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace $namespace

kubectl apply -f admin-user.yaml
kubectl apply -f crb.yaml
kubectl apply -f token.yaml

echo
echo "Login Token:"
echo
kubectl get secrets -n kubernetes-dashboard -ojsonpath='{.data.token}' admin-user | base64 -d
echo
echo

kubectl rollout status deployment -n kubernetes-dashboard kubernetes-dashboard-kong

kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy $port:443 &

open https://localhost:$port
