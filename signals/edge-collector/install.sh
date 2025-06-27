#!/bin/bash

namespace=telemetry-edge

kubectl create ns $namespace
kubectl annotate ns $namespace linkerd.io/inject=enabled

kubectl apply -f resources/certificate.yaml
kubectl apply -f resources/cluster-role.yaml
kubectl apply -f resources/cluster-role-binding.yaml

helm upgrade --install telemetry-edge-gateway open-telemetry/opentelemetry-collector \
  -f helm/edge-collector.yaml \
  -n $namespace

kubectl rollout status deployment -n $namespace telemetry-edge-gateway
