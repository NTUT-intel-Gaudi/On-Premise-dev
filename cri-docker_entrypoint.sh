#!bin/sh
sudo swapoff -a
sudo cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo kubeadm reset --config=kubeadm-config.yaml
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni/
sudo rm $HOME/.kube/config

sudo kubeadm init --config=kubeadm-config.yaml

sudo mkdir $HOME/.kube/
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# journalctl -u kubelet -f
kubectl apply -f calico.yaml
kubectl get pods -A --watch