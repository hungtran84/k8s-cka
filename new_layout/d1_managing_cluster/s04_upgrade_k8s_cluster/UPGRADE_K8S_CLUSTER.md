# Upgrade Kubernetes Cluster

Use Kubeadm to upgrade a Kubernetes cluster

The upgrade workflow at high level is the following:

Upgrade the control plane node.
Upgrade worker nodes.

## Step

Demo upgrade cluster from 1.18.6 -> 1.18.8

- Get the version of the api server

```
kubectl version --short
```

- View the version of kubelet

```
kubectl get nodes -o wide
kubectl describe nodes 
```

- View the version of controller-manager pod

```
kubectl get pods -n kube-system
kubectl get pods kube-apiserver-k8s-node-1  -o yaml -n kube-system
```

### Start on Control plane

- Release the hold on versions of kubeadm and kubelet

```
apt-mark unhold kubeadm kubelet
```

- Install version 1.18.8 of kubeadm

```
apt-get install -y kubeadm=1.18.8-00
```

- Hold the version of kubeadm at 1.18.8

```
apt-mark hold kubeadm
```

- Verify the version of kubeadm

```
kubeadm version
```

- Plan the upgrade of all the controller components

```
kubeadm upgrade plan
```

- Upgrade the controller components

```
kubeadm upgrade apply v1.18.8
```

- Release the hold on the version of kubectl

```
apt-mark unhold kubectl
```

- Upgrade kubectl

```
apt-get install -y kubectl=1.18.8-00
```

- Hold the version of kubectl at 1.18.8

```
apt-mark hold kubectl
```

- Unhold kubelet

```
apt-mark unhold kubelet
```

- Upgrade kubelet to 1.18.8

```
apt-get install -y kubelet=1.18.8-00
```

- Hold the version of kubelet at 1.18.8

```
apt-mark hold kubelet
```

- Restart

```
systemctl daemon-reload
systemctl restart kubelet
```


### Worker Node

- Drain the node
Prepare the node for maintenance by marking it unschedulable and evicting the workloads:

```
kubectl drain <node-to-drain> --ignore-daemonsets
```

- Upgrade kubeadm

```
apt-mark unhold kubeadm
apt-get install -y kubeadm=1.18.8-00
apt-mark hold kubeadm
```

- Upgrade kubelet configuration

```
kubeadm upgrade node
```

- Upgrade kubelet and kubectl

```
apt-mark unhold kubelet kubectl 
apt-get install -y kubelet=1.18.8-00 kubectl=1.18.8-00
apt-mark hold kubelet kubectl
```

- Restart

```
systemctl daemon-reload
systemctl restart kubelet
```

- Uncordon the node

```
kubectl uncordon <node-to-drain>
```

### Reference command

- Evict the pods on node

```
kubectl drain [node_name] --ignore-daemonsets
```

- Schedule pods on node

```
kubectl uncordon [node_name]
```

- List the current tokens

```
kubeadm token list
```

- Get new token to join

```
kubeadm token generate
```

- Print the kubeadm join command

```
kubeadm token create <token_name> --ttl 23h --print-join-command
```s
