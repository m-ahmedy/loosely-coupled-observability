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

echo
echo "Installing decoupling components"
echo "Installing Strimzi operator and Kafka components"
pushd decoupling/kafka
./install.sh
popd

echo
echo "Installing telemetry gateway collector"
pushd decoupling/gateway-collector
./install.sh
popd

# Installing edge collector as well
echo
echo "Installing telemetry edge collector"
pushd signals/edge-collector
./install.sh
popd
