#!bin/sh

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"
cd ../config

# kubernetes dependencies

# apply network add on
kubectl apply -f calico.yaml

# apply storage class
# kubectl apply -f local-path-storage.yaml

# apply 
# kubectl create namespace argocd
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

cd /home/james/tools/manifests
kustomize build example | kubectl apply -f -