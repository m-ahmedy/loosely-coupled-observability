#!/bin/bash

kubectl create namespace kafka
# kubectl annotate ns kafka linkerd.io/inject=enabled

helm upgrade --install strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator --namespace kafka --create-namespace -f helm/values.yaml

kubectl rollout status deployment -n kafka strimzi-cluster-operator

kubectl apply -f crds/kafka.yaml
kubectl wait -n kafka --for condition=ready --timeout=10m kafka telemetry

kubectl apply -f crds/topics.yaml
kubectl apply -f crds/users

kubectl apply -f redpanda.yaml
kubectl rollout status deployment -n kafka redpanda-console

kubectl port-forward -n kafka svc/redpanda-console 8081:8080
