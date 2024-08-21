#!bin/sh
set -euo pipefail

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"

cd ./argocd-config

kubectl apply -f kubeflow.yaml
kubectl apply -f myapp.yaml