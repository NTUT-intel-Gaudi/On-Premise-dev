#!bin/sh

autoInit=false
cri=containerd

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"

sudo swapoff -a
sudo modprobe br_netfilter
sudo modprobe overlay

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo kubeadm reset --cri-socket=unix:///var/run/containerd/containerd.sock --force
sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock --force
sudo rm -rf /etc/cni/
sudo rm -rf /var/lib/cni/
sudo rm -rf /var/lib/kubelet/*
sudo rm $HOME/.kube/config

sudo ifconfig cni0 down
sudo ifconfig flannel.1 down
sudo ip link delete cni0
sudo ip link delete flannel.1

sudo systemctl restart containerd
sudo systemctl restart kubelet

cd ../config
if [ "$autoInit" = "true" ]; then
    if [ "$cri" = "containerd" ]; then
        sudo kubeadm init --config=kubeadm-config_docker.yaml --v=5
    elif [ "$cri" = "docker" ]; then
        sudo kubeadm init --config=kubeadm-config_containerd.yaml --v=5
    fi
    sudo mkdir $HOME/.kube/
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
fi

