#!/bin/bash
# Run this on the HEAD node
# Disable swap
echo "##### Disabling swap..."
sudo swapoff -a

# Install prerequisites
echo 
echo "##### Running apt-update and installing prerequisite packages..."
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common nginx

# Install Docker
echo
echo "##### Installing Docker..."
sudo apt-get install -y docker.io

# Install Kubernetes
echo 
echo "##### Installing Kubernetes 1.18.1"
sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo apt-get update && sudo apt-get install -y \
  kubelet=1.18.1-00 \
  kubeadm=1.18.1-00 \
  kubectl=1.18.1-00
# Hold the versions to prevent automatic upgrades leading to incompatibilities
sudo apt-mark hold docker-ce kubelet kubeadm kubectl

# Install Helm
echo
echo "##### Installing Helm 3..."
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install NFS Server
echo
echo "##### Installing NFS..."
sudo apt-get install nfs-common -y
echo
echo "##### Done!"
