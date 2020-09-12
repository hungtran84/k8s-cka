# CENTOS

### Installing Docker

```
###Add yum-utils, if not installed already
yum install yum-utils

###Add Docker repository.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

###Install Docker CE.
yum install docker-ce docker-ce-cli containerd.io

### Restart Docker
systemctl daemon-reload
systemctl enable docker
systemctl restart docker
```

### Disable SELinux

```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disable/' /etc/selinux/config
```

### Disable Swap

```
sed -i '/swap/d' /etc/fstab
swapoff -a
```

### Disable Firewall

```
systemctl disable firewalld
systemctl stop firewalld
```

### Update IPTables

```
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

### Install kubelet/kubeadm/kubectl

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables
echo '1' > /proc/sys/net/ipv4/ip_forward

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet
```
