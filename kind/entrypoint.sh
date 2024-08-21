#!/bin/sh


sudo sysctl fs.inotify.max_user_instances=2280
sudo sysctl fs.inotify.max_user_watches=1255360

cat <<EOF | kind create cluster --name=kubeflow --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.29.4
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        "service-account-issuer": "kubernetes.default.svc"
        "service-account-signing-key-file": "/etc/kubernetes/pki/sa.key"
- role: worker
  image: kindest/node:v1.29.4
- role: worker
  image: kindest/node:v1.29.4
EOF

kind get kubeconfig --name kubeflow > /tmp/kubeflow-config
export KUBECONFIG=/tmp/kubeflow-config

docker login

kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=/home/james/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson

# cd /home/james/workspace/tools/manifests
# while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 20; done