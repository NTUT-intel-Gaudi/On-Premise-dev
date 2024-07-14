# prerequisites

## disable swap

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

##