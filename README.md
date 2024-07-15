# prerequisites

## disable swap

MUST disable swap if the kubelet is not properly configured to use swap
```bash
sudo swapoff -a
```

## enable IPv4 packet forwarding

```bash
#sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
# Apply sysctl params without reboot
sudo sysctl --system
```

## verify MAC address and product_uuid are unique for every node

It might not be unique in **virtual machines** and produce [error](https://github.com/kubernetes/kubeadm/issues/31)

```bash
# MAC addr
ip link or ifconfig -a
# product_uuid
sudo cat /sys/class/dmi/id/product_uuid
```

## check required ports

```bash
# TCP Inbound 6443 Kubernetes API server All
# TCP Inbound 2379-2380 etcd server client API kube-apiserver, etcd
# TCP Inbound 10250 Kubelet API Self, Control plane
# TCP Inbound 10259 kube-scheduler Self
# TCP Inbound 10257 kube-controller-manager Self
nc 127.0.0.1 6443 -v
```

## making kubectl work

as non-root user

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

as root user

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```