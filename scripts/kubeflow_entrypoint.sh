#!bin/sh

cd /home/james/tools/manifests

# install cert manager
kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
echo "Waiting for cert-manager to be ready ..."
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl wait --for=jsonpath='{.subsets[0].addresses[0].targetRef.kind}'=Pod endpoints -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager

# install istio
echo "Installing Istio configured with external authorization..."
kustomize build common/istio-1-22/istio-crds/base | kubectl apply -f -
kustomize build common/istio-1-22/istio-namespace/base | kubectl apply -f -
kustomize build common/istio-1-22/istio-install/overlays/oauth2-proxy | kubectl apply -f -

echo "Waiting for all Istio Pods to become ready..."
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout 300s

# install Oauth2-proxy
echo "Installing oauth2-proxy..."
kustomize build common/oidc-client/oauth2-proxy/overlays/m2m-self-signed/ | kubectl apply -f -
kubectl wait --for=condition=ready pod -l 'app.kubernetes.io/name=oauth2-proxy' --timeout=180s -n oauth2-proxy

# install dex
kustomize build common/dex/overlays/oauth2-proxy | kubectl apply -f -

# install Knative
kustomize build common/knative/knative-serving/overlays/gateways | kubectl apply -f -
kustomize build common/istio-1-22/cluster-local-gateway/base | kubectl apply -f -

# install Kubeflow Namespace
kustomize build common/kubeflow-namespace/base | kubectl apply -f -

# install Kubeflow Roles
kustomize build common/kubeflow-roles/base | kubectl apply -f -
