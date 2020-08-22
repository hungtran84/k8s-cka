# Kubeadm

Use Kubeadm to create a Kubernetes cluster

## Setup

### Install Dependency

- Docker
- Kubeadm
- Kubelet


```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat << EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

```
apt-get update
apt-get install -y docker-ce=5:19.03.12~3-0~ubuntu-xenial \
        kubelet=1.18.6-00 \
        kubeadm=1.18.6-00 kubectl=1.18.6-00
```

- To hold the version

```
apt-mark hold docker-ce kubelet kubeadm
```

### Setup Master Node
 
- Get the public ip node

```
kubeadm init --apiserver-cert-extra-sans=<public-ip> --pod-network-cidr=10.244.0.0/16
```

```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

### Join Worker Node

- Get the master node join command

```
kubeadm join <internal-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<ca-cert>
```

### Install CNI

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

### Test

- Deploy nginx

```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

- Verify pod can run

```
kubectl get pods
kubectl get deployments
```

- Verify pods can access directly

```
kubectl port-forward pods/<pod-id> 8081:80
curl --head http://localhost:8081
```

- View logs

```
kubectl logs -f pod-id
```

- Service can access

```
kubectl expose deployment nginx-deployment --type NodePort --port 80
kubectl get services
```

- Check access

```
curl --head http://localhost:nodeport
```

- Get node status

```
kubectl get nodes
```

- Get detail info pods

```
kubectl describe pods
```

## Clean up

### Remove Worker Node

```
kubectl drain <node_name> --delete-local-data --force --ignore-daemonsets
```

- On Worker Node

```
kubeadm reset
```

- Then remove node

```
kubectl delete <node_name>
```

### Clean up Control Plane

```
kubeadm reset
```