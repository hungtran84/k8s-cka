# CENTOS

### Installing Docker

```
###Add yum-utils, if not installed already
yum install yum-utils

###Add Docker repository.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

###Install Docker CE.
yum update && yum install docker-ce-18.06.2.ce

###Create /etc/docker directory.
mkdir /etc/docker

###Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

###Restart Docker
systemctl daemon-reload
systemctl enable docker.service
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
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
```
