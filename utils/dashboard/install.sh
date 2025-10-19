#!/bin/bash

port=8443
namespace=kubernetes-dashboard

kubectl create namespace $namespace
kubectl annotate namespace $namespace linkerd.io/inject=enabled

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ --force-update

helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace $namespace -f helm/dashboard.yaml

kubectl apply -f resources/admin-user.yaml
kubectl apply -f resources/crb.yaml
kubectl apply -f resources/token.yaml

echo
echo "Login Token:"
echo
token=$(kubectl get secrets -n kubernetes-dashboard -ojsonpath='{.data.token}' admin-user | base64 -d)
echo $token
echo $token > dashboard.token
echo

kubectl rollout status deployment -n kubernetes-dashboard kubernetes-dashboard-kong

kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy $port:443 2>&1 &

open https://localhost:$port
