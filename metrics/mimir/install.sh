#!/bin/bash

kafka_namespace=kafka
namespace=mimir

kubectl create ns $namespace
kubectl annotate ns $namespace linkerd.io/inject=enabled

secrets=(metrics-consumer)

for secret in "${secrets[@]}"
do
  password=$(kubectl get secrets -n $kafka_namespace $secret -ojsonpath='{.data.password}' | base64 -d)
  kubectl create secret generic $secret -n $namespace --from-literal=password=$password
done

helm upgrade --install mimir grafana/mimir-distributed -f helm/mimir.yaml --namespace $namespace --create-namespace

kubectl rollout status deployment -n $namespace mimir-distributor

helm upgrade --install grafana grafana/grafana \
  -n $namespace \
  -f helm/grafana.yaml

kubectl rollout status deployment -n $namespace grafana

helm upgrade --install mimir-gateway open-telemetry/opentelemetry-collector \
  -f helm/mimir-otel-collector.yaml \
  -n $namespace --create-namespace

kubectl rollout status deployment -n $namespace mimir-gateway-opentelemetry-collector

kubectl port-forward -n mimir svc/grafana 8082:80
