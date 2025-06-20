#!/bin/bash

port=8083
namespace=jaeger

kubectl create namespace $namespace
kubectl annotate ns $namespace linkerd.io/inject=enabled

helm upgrade --install jaeger jaegertracing/jaeger \
  -n $namespace \
  -f helm/jaeger.yaml

kubectl rollout status deployment -n $namespace jaeger-collector

helm upgrade --install jaeger-gateway open-telemetry/opentelemetry-collector \
  -f helm/otel-collector.yaml \
  -n $namespace

kubectl rollout status deployment -n $namespace jaeger-gateway-opentelemetry-collector
