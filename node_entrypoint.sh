#!bin/sh

# get join command
# kubeadm token create $(kubeadm token generate) --print-join-command --ttl=0

kubectl join [create] --cri-socket=unix:///var/run/cri-dockerd.sock

#[ERROR FileAvailable--etc-kubernetes-kubelet.conf]: /etc/kubernetes/kubelet.conf already exists
#[ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists
sudo rm /etc/kubernetes/kubelet.conf
sudo rm /etc/kubernetes/pki/ca.crt
sudo rm /etc/kubernetes/bootstrap-kubelet.conf
