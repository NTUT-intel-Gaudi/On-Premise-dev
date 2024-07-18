#!bin/sh
set -euo pipefail

# get join command
# kubeadm token create $(kubeadm token generate) --print-join-command --ttl=0
sudo swapoff -a # kubectl will fail healthy check if swap is not disabled
sudo cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock
# kubectl join [create] --cri-socket=unix:///var/run/cri-dockerd.sock

#[ERROR FileAvailable--etc-kubernetes-kubelet.conf]: /etc/kubernetes/kubelet.conf already exists
#[ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists
sudo rm /etc/kubernetes/kubelet.conf
sudo rm /etc/kubernetes/pki/ca.crt
sudo rm /etc/kubernetes/bootstrap-kubelet.conf

kubectl apply -f calico.yaml
kubectl get pods -A --watch