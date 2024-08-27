#!bin/sh
set -euo pipefail

cri=containerd
os=debian
arch=amd64

THIS_SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
cd "$THIS_SCRIPT_PATH"

sudo apt update
sudo apt upgrade
sudo install -m 0755 -d /etc/apt/keyrings

# install kubelet kubeadm kubectl
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

# install container interface

if [ "$cri" = "containerd" ]; then
  if [ "$arch" = "amd64" ]; then
    # install containerd from the official binaries
    wget https://github.com/containerd/containerd/releases/download/v1.7.21/containerd-1.7.21-linux-amd64.tar.gz
    sudo tar Cxzvf /usr/local containerd-1.7.21-linux-amd64.tar.gz
    sudo mkdir -p /usr/local/lib/systemd/system
    sudo wget -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now containerd
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    # set SystemdCgroup to true for runc
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    sudo systemctl restart containerd
    # install runc
    wget https://github.com/opencontainers/runc/releases/download/v1.1.13/runc.amd64
    sudo install -m 755 runc.amd64 /usr/local/sbin/runc
    # install cni plugin
    wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
    sudo mkdir -p /opt/cni/bin
    sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz
    # install kubeadm images for containerd
    sudo kubeadm config images pull --cri-socket=/run/containerd/containerd.sock --kubernetes-version=v1.31.0
  fi

elif [ "$cri" = "docker" ]; then
  sudo apt-get update
  sudo curl -fsSL "https://download.docker.com/linux/$os/gpg" -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] "https://download.docker.com/linux/$os" \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker

  if [ "$arch" = "amd64" ]; then
    # install cri-dockerd
    wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb
    sudo dpkg -i cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb
    rm cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb

    systemctl daemon-reload
    systemctl enable cri-docker.service
    systemctl enable --now cri-docker.socket
  elif [ "$arch" = "arm64" ]; then
    echo "Not supported"
    # https://alexsniffin.medium.com/a-guide-to-building-a-kubernetes-cluster-with-raspberry-pis-23fa4938d420
  fi
fi

# install kustomize

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# install nvidia container toolkit (runtime for docker)

# curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
#   && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
# sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
# sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
# sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list

# sudo apt-get update
# sudo apt-get install -y nvidia-container-toolkit
# sudo nvidia-ctk runtime configure --runtime=docker
# sudo systemctl restart docker