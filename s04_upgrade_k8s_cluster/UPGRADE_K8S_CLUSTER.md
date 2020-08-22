# Upgrade Kubernetes Cluster

Use Kubeadm to upgrade a Kubernetes cluster

## Step

- Get the version of the api server

```
kubectl version --short
```

- View the version of kubelet

```
kubectl describe nodes 
```

- View the version of controller-manager pod

```
kubectl get po [controller_pod_name] -o yaml -n kube-system
```

- Release the hold on versions of kubeadm and kubelet

```
sudo apt-mark unhold kubeadm kubelet
```

- Install version 1.16.6 of kubeadm

```
sudo apt install -y kubeadm=1.16.6-00
```

- Hold the version of kubeadm at 1.16.6

```
sudo apt-mark hold kubeadm
```


### 


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
kubeadm upgrade apply v1.16.6
```

- Release the hold on the version of kubectl

```
apt-mark unhold kubectl
```

- Upgrade kubectl

```
apt-install -y kubectl=1.16.6-00
```

- Hold the version of kubectl at 1.16.6

```
apt-mark hold kubectl
```

- Upgrade kubelet to 1.16.6

```
apt install -y kubelet=1.16.6-00
```

- hold the version of kubelet at 1.16.6

```
apt-mark hold kubelet
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
