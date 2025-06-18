#!/bin/bash

kubectl create namespace jaeger
kubectl annotate ns jaeger linkerd.io/inject=enabled

helm upgrade --install jaeger jaegertracing/jaeger \
  -n jaeger --create-namespace \
  -f helm/jaeger.yaml

kubectl wait --for condition=available -n jaeger deployment/jaeger-collector --timeout=10m

helm upgrade --install jaeger-gateway open-telemetry/opentelemetry-collector \
  -f helm/otel-collector.yaml \
  -n jaeger --create-namespace

kubectl wait --for condition=available -n jaeger --timeout=300s deployment/jaeger-gateway-opentelemetry-collector
