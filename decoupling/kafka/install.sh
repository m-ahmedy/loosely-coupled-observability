#!/bin/bash

port=8081
namespace=kafka

kubectl create namespace $namespace
# kubectl annotate ns kafka linkerd.io/inject=enabled

helm upgrade --install strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator --namespace $namespace -f helm/values.yaml

kubectl rollout status deployment -n $namespace strimzi-cluster-operator

kubectl apply -f crds/kafka.yaml
kubectl wait -n $namespace --for condition=ready --timeout=10m kafka telemetry

kubectl apply -f crds/topics.yaml
kubectl apply -f crds/users

kubectl apply -f redpanda.yaml
kubectl rollout status deployment -n $namespace redpanda-console

kubectl port-forward -n $namespace svc/redpanda-console $port:8080 &

open http://localhost:$port
