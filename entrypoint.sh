#!bin/sh
set -euo pipefail

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"

swapoff -a
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sysctl --system
kubeadm reset
rm $HOME/.kube/config
kubeadm init --pod-network-cidr=192.168.0.0/24 --cri-socket=unix:///var/run/cri-dockerd.sock

mkdir $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# journalctl -u kubelet -f