#!bin/sh

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"

sudo swapoff -a
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock --force
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni/
sudo rm $HOME/.kube/config

cd ../config
sudo kubeadm init --config=kubeadm-config.yaml

sudo mkdir $HOME/.kube/
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# apply network add on
kubectl apply -f calico.yaml

# apply storage class
kubectl apply -f local-path-storage.yaml

# apply 
# kubectl create namespace argocd
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml