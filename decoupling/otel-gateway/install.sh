#!/bin/bash

kafka_namespace=kafka
namespace=otel-gateway

kubectl create ns $namespace
kubectl annotate ns $namespace linkerd.io/inject=enabled

secrets=(traces-producer metrics-producer logs-producer)

for secret in "${secrets[@]}"
do
  password=$(kubectl get secrets -n $kafka_namespace $secret -ojsonpath='{.data.password}' | base64 -d)
  kubectl create secret generic $secret -n $namespace --from-literal=password=$password
done

helm upgrade --install otel-gateway open-telemetry/opentelemetry-collector \
  -f helm/values.yaml \
  -n $namespace --create-namespace

kubectl rollout status deployment -n $namespace otel-gateway-opentelemetry-collector

kubectl apply -f clusterrole.yaml
kubectl apply -f crb.yaml
