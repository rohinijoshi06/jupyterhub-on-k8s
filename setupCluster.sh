#!/bin/bash
set -e

# Initialise a cluster with pod CIDR 10.244.0.0/16. Be careful that this IP range does not conflict with that of your nodes. 
# pod CIDR 192.168.0.0/16 is the default for Calico
echo "##### Initialising cluster..."
sudo kubeadm init --kubernetes-version 1.18.1 --pod-network-cidr=10.244.0.0/16 | tee clusterInit.out
echo "##### Output of cluster initialisation saved to clusterInit.out, use to find the join command to connect worker nodes to the cluster"

echo
echo "##### Save kubeconfig as per the instructions above..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo
echo "##### Setup Flannel for networking on the cluster..."
sudo kubectl apply -f kube-flannel.yaml

echo
echo "##### Enable bash auto completion for kubectl..."
sudo apt-get install bash-completion -y
echo "source <(kubectl completion bash)" >> $HOME/.bashrc

echo
echo "##### Done, Head node and any worker nodes added should soon be visible."
