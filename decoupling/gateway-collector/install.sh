#!/bin/bash

kafka_namespace=kafka
namespace=telemetry-gateway

kubectl create ns $namespace
kubectl annotate ns $namespace linkerd.io/inject=enabled

secrets=(traces-producer metrics-producer logs-producer)

for secret in "${secrets[@]}"
do
  password=$(kubectl get secrets -n $kafka_namespace $secret -ojsonpath='{.data.password}' | base64 -d)
  kubectl create secret generic $secret -n $namespace --from-literal=password=$password
done

kubectl apply -f resources/

helm upgrade --install telemetry-gateway open-telemetry/opentelemetry-collector \
  -f helm/values.yaml \
  -n $namespace

kubectl rollout status deployment -n $namespace telemetry-gateway
