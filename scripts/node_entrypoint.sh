#!bin/sh

autoJoin=false

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"

# get join command
# kubeadm token create $(kubeadm token generate) --print-join-command --ttl=0
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
#[ERROR FileAvailable--etc-kubernetes-kubelet.conf]: /etc/kubernetes/kubelet.conf already exists
#[ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists
sudo rm /etc/kubernetes/kubelet.conf
sudo rm /etc/kubernetes/pki/ca.crt
sudo rm /etc/kubernetes/bootstrap-kubelet.conf

sudo rm -rf /etc/cni/net.d

sudo systemctl restart containerd
sudo systemctl restart kubelet

cd ../config

if [ "$autoJoin" = "true" ]; then
    sudo kubeadm join --config kubeadm-normal-node-config.yaml
fi