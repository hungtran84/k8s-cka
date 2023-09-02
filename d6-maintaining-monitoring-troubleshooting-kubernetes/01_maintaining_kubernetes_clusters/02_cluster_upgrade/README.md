# Cluster upgrade
## Find the version you want to upgrade to. 
- You can only upgrade one minor version to the next minor version
```
sudo apt update
apt-cache policy kubeadm | head
```

- What version are we on?
```
kubectl version --output yaml
kubectl get nodes
```

## Upgrade Control Plane nodes
- First, upgrade kubeadm on the Control Plane Node
Replace the version with the version you want to upgrade to.

```
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.1-00
sudo apt-mark hold kubeadm
```

- Next, `drain` any workload on the Control Plane Node node
```
kubectl drain cp1 --ignore-daemonsets
```

- Run upgrade plan to test the upgrade process and run pre-flight checks.
Highlights additional work needed after the upgrade, such as manually updating the kubelets.
And displays version information for the control plan components
```
$ sudo kubeadm upgrade plan v1.28.1

components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       TARGET
kubelet     4 x v1.27.0   v1.28.1

Upgrade to the latest version in the v1.27 series:

COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.27.0   v1.28.1
kube-controller-manager   v1.27.0   v1.28.1
kube-scheduler            v1.27.0   v1.28.1
kube-proxy                v1.27.0   v1.28.1
CoreDNS                   v1.10.1   v1.10.1
etcd                      3.5.7-0   3.5.9-0
```

- Prepull image beforehand
```
kubeadm config images pull
```

- Run the upgrade, you can get this from the previous output.
```
sudo kubeadm upgrade apply v1.28.1
```

- Uncordon the control plane node `cp1`
```
kubectl uncordon cp1 
```

- Now update the `kubelet` and `kubectl` on the control plane node(s)
```
sudo apt-mark unhold kubelet kubectl 
sudo apt-get update
sudo apt-get install -y kubelet=1.28.1-00 kubectl=1.28.1-00
sudo apt-mark hold kubelet kubectl
```

- Check the update status
```
kubectl version -oyaml
kubectl get nodes
```

> [!NOTE]  
> Upgrade any additional control plane nodes with the same process.

## Upgrade worker nodes
- Rolling upgrade the workers one-by-one, drain the node, then log into it. 
```shell
# run from local or `cp1`
kubectl drain node1 --ignore-daemonsets
```

- Access to the target node
```
gcloud compute ssh node1
```

- First, upgrade kubeadm 
```
sudo apt-mark unhold kubeadm 
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.1-00
sudo apt-mark hold kubeadm
```

- Updates `kubelet` configuration for the node
```
sudo kubeadm upgrade node
```

- Update the `kubelet` and `kubectl` on the node
```
sudo apt-mark unhold kubelet kubectl 
sudo apt-get update
sudo apt-get install -y kubelet=1.28.1-00 kubectl=1.28.1-00
sudo apt-mark hold kubelet kubectl
```

- Log out of the node
```
exit
```

- Get the nodes to show the version. It can take a second to update
```
kubectl get nodes 
```

- Uncordon the node to allow workload again
```
kubectl uncordon node1
```

- Upgrade the other worker nodes (node2, node3) with the same process

- Check the versions of the nodes
```
kubectl get nodes
```