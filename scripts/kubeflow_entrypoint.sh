#!bin/sh

cd /home/james/tools/manifests

# kubernetes dependencies

# apply network add on
# kubectl apply -f calico.yaml

# apply storage class
# kubectl apply -f local-path-storage.yaml

# apply 
# kubectl create namespace argocd
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# kubeflow dependencies

# install cert manager
kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
echo -e "\e[32mWaiting for cert-manager to be ready ...\e[0m"
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl wait --for=jsonpath='{.subsets[0].addresses[0].targetRef.kind}'=Pod endpoints -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager

# install istio
echo -e "\e[32mInstalling Istio configured with external authorization...\e[0m"
kustomize build common/istio-1-22/istio-crds/base | kubectl apply -f -
kustomize build common/istio-1-22/istio-namespace/base | kubectl apply -f -
kustomize build common/istio-1-22/istio-install/overlays/oauth2-proxy | kubectl apply -f -

echo -e "\e[32mWaiting for all Istio Pods to become ready...\e[0m"
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s || \
kubectl wait --for=status=Completed pods --all -n istio-system --timeout=300s

# install Oauth2-proxy
echo -e "\e[32mInstalling oauth2-proxy...\e[0m"
kustomize build common/oidc-client/oauth2-proxy/overlays/m2m-self-signed/ | kubectl apply -f -
kubectl wait --for=condition=ready pod -l 'app.kubernetes.io/name=oauth2-proxy' --timeout=180s -n oauth2-proxy

# install dex
echo -e "\e[32mInstalling dex...\e[0m"
kustomize build common/dex/overlays/oauth2-proxy | kubectl apply -f -

# install Knative
echo -e "\e[32mInstalling Knative Serving...\e[0m"
kustomize build common/knative/knative-serving/overlays/gateways | kubectl apply -f -
kustomize build common/istio-1-22/cluster-local-gateway/base | kubectl apply -f -

# install Kubeflow Namespace
echo -e "\e[32mInstalling Kubeflow Namespace...\e[0m"
kustomize build common/kubeflow-namespace/base | kubectl apply -f -

# install Kubeflow Roles
echo -e "\e[32mInstalling Kubeflow Roles...\e[0m"
kustomize build common/kubeflow-roles/base | kubectl apply -f -

# kubeflow application

# install KServe
echo -e "\e[32mInstalling KServe...\e[0m"
kustomize build contrib/kserve/kserve | kubectl apply -f -
kustomize build contrib/kserve/models-web-app/overlays/kubeflow | kubectl apply -f -

# install Katib
echo -e "\e[32mInstalling Katib...\e[0m"
kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -

# install Central Dashboard
echo -e "\e[32mInstalling Central Dashboard...\e[0m"
kustomize build apps/centraldashboard/upstream/overlays/kserve | kubectl apply -f -

# install Admission Webhook
echo -e "\e[32mInstalling Admission Webhook...\e[0m"
kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

# install Notebook 1.0
echo -e "\e[32mInstalling Notebook 1.0...\e[0m"
kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -

# install PVC Viewer Controller
echo -e "\e[32mInstalling PVC Viewer Controller...\e[0m"
kustomize build apps/pvcviewer-controller/upstream/default | kubectl apply -f -

# install Profiles + KFAM
echo -e "\e[32mInstalling Profiles + KFAM...\e[0m"
kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -

# install Volumes Web Application
echo -e "\e[32mInstalling Volumes Web Application...\e[0m"
kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -

# install TensorBoard
echo -e "\e[32mInstalling TensorBoard...\e[0m"
kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -

# install Training Operator
echo -e "\e[32mInstalling Training Operator...\e[0m"
kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply -f -

# install Namespaces
echo -e "\e[32mInstalling Namespaces...\e[0m"
kustomize build common/user-namespace/base | kubectl apply -f -
