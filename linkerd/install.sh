#!/bin/bash

linkerd check --pre

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

linkerd check --wait=10m0s

linkerd viz install | kubectl apply -f -
linkerd viz check

linkerd viz dashboard 
