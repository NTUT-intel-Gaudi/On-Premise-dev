#!bin/sh


THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"
cd ../config

# apply flannel cni
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# apply local-path storage (rancher dynamic volume provisioner)
kubectl apply -f local-path-storage.yaml