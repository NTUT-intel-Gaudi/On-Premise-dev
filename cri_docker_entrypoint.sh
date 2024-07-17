#!bin/sh
sudo swapoff -a
sudo cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock
sudo rm $HOME/.kube/config
sudo kubeadm init --pod-network-cidr=192.168.0.0/24 --cri-socket=unix:///var/run/cri-dockerd.sock

sudo mkdir $HOME/.kube/
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# journalctl -u kubelet -f