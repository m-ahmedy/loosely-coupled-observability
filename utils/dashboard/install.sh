#!/bin/bash

kubectl create ns kubernetes-dashboard
kubectl annotate ns kubernetes-dashboard linkerd.io/inject=enabled

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

kubectl annotate ns kubernetes-dashboard linkerd.io/inject=enabled

kubectl apply -f admin-user.yaml
kubectl apply -f crb.yaml
kubectl apply -f token.yaml

echo
kubectl get secrets -n kubernetes-dashboard -ojsonpath='{.data.token}' admin-user | base64 -d

echo
kubectl rollout status deployment -n kubernetes-dashboard kubernetes-dashboard-kong

kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
