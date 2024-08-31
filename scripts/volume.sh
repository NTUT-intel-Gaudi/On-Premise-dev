#!bin/sh

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"
cd ../config

# apply storage class
kubectl apply -f sc-config.yaml
kubectl apply -f pv-volume01.yaml
kubectl apply -f pv-volume02.yaml
kubectl apply -f pv-volume03.yaml