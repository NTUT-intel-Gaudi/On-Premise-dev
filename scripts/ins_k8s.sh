#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <k8s_version>"
  exit 1
fi

k8s_version=$1
read -p "installing k8s with version: $k8s_version..."

sudo apt update
sudo apt upgrade
sudo install -m 0755 -d /etc/apt/keyrings
sudo apt install net-tools jq apt-transport-https ca-certificates curl gpg

# install systemd-resolved
sudo apt install systemd-resolved
sudo systemctl restart systemd-resolved
sudo systemctl enable systemd-resolved

# install kubelet kubeadm kubectl
curl -fsSL "https://pkgs.k8s.io/core:/stable:/$k8s_version/deb/Release.key" | sudo gpg --dearmor -o "/etc/apt/keyrings/kubernetes-$k8s_version-apt-keyring.gpg"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-$k8s_version-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$k8s_version/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

# install kustomize

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# install helm

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm