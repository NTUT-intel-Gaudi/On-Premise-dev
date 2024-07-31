#!bin/sh

cd /home/james/tools/manifests

# kubeflow dependencies

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
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s || \
kubectl wait --for=condition=Complete pods --all -n istio-system --timeout=300s

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

# kubeflow application

# install KServe
kustomize build contrib/kserve/kserve | kubectl apply -f -
kustomize build contrib/kserve/models-web-app/overlays/kubeflow | kubectl apply -f -

# install Katib
kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -

# install Central Dashboard
kustomize build apps/centraldashboard/upstream/overlays/kserve | kubectl apply -f -

# install Admission Webhook
kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

# install Notebook 1.0
kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -

# install PVC Viewer Controller
kustomize build apps/pvcviewer-controller/upstream/default | kubectl apply -f -

# install Profiles + KFAM
kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -

# install Volumes Web Application
kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -

# install TensorBoard
kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -

# install Training Operator
kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply -f -

# install Namespaces
kustomize build common/user-namespace/base | kubectl apply -f -
