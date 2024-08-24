#!bin/sh

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"

sudo swapoff -a
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo kubeadm reset --cri-socket=unix:///var/run/containerd/containerd.sock --force
sudo rm -rf /etc/cni/
sudo rm -rf /var/lib/cni/
# sudo rm -rf /var/lib/kubelet/*
# sudo rm -rf /run/flannel
sudo rm $HOME/.kube/config

# sudo systemctl stop kubelet
# sudo systemctl stop docker

# sudo ifconfig cni0 down
# sudo brctl delbr cni0
# sudo ifconfig flannel.1 down
# sudo systemctl start docker

cd ../config
sudo kubeadm init --config=kubeadm-config_docker.yaml

sudo mkdir $HOME/.kube/
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config