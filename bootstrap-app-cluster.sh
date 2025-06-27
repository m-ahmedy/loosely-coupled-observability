#!/bin/bash

echo
echo "Install linkerd service mesh"
pushd sidecars/linkerd
./install.sh
popd

echo
echo "Install cert-manager"
pushd security/cert-manager
./install.sh
popd

echo
echo "Install nginx ingress controller"
pushd ingress
./install.sh
popd

echo
echo "Install Kubernetes Dashboard"
pushd utils/dashboard
./install.sh
popd


echo "Installing metrics collector"
pushd signals/metrics/app-cluster-collector
./install.sh
popd

