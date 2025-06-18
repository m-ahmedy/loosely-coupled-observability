#!/bin/bash

kafka_namespace=kafka
namespace=thanos

kubectl create ns $namespace
kubectl annotate ns $namespace linkerd.io/inject=enabled

kubectl apply -f secrets.yaml

secrets=(metrics-consumer)

for secret in "${secrets[@]}"
do
  password=$(kubectl get secrets -n $kafka_namespace $secret -ojsonpath='{.data.password}' | base64 -d)
  kubectl create secret generic $secret -n $namespace --from-literal=password=$password
done

helm upgrade --install minio bitnami/minio -n $namespace -f helm/minio.yaml
helm upgrade --install thanos bitnami/thanos -n $namespace -f helm/thanos.yaml
helm upgrade --install grafana grafana/grafana -n $namespace -f helm/grafana.yaml
helm upgrade --install thanos-gateway open-telemetry/opentelemetry-collector \
  -f helm/thanos-otel-collector.yaml \
  -n $namespace

kubectl rollout status deployment -n $namespace thanos-gateway-opentelemetry-collector

kubectl port-forward -n thanos svc/grafana 8082:80
