#!/bin/bash

linkerd check --pre

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

linkerd check --wait=10m0s

linkerd viz install | kubectl apply -f -
linkerd viz check

echo "To view linkerd dashboard"
echo "    linkerd viz dashboard"
