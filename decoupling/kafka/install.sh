#!/bin/bash

port=8081
namespace=kafka

kubectl create namespace $namespace
# kubectl annotate ns kafka linkerd.io/inject=enabled

helm upgrade --install strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator --namespace $namespace -f helm/values.yaml

kubectl rollout status deployment -n $namespace strimzi-cluster-operator

kubectl apply -f resources/kafka.yaml
kubectl wait -n $namespace --for condition=ready --timeout=10m kafka telemetry

kubectl apply -f resources/topics.yaml
kubectl apply -f resources/users

kubectl apply -f redpanda.yaml
kubectl rollout status deployment -n $namespace redpanda-console

echo "To open redpanda console:"
echo "    kubectl port-forward -n $namespace svc/redpanda-console $port:8080 &"
