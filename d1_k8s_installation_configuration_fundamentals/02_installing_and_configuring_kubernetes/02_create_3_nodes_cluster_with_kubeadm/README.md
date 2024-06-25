## Create the kubeadm-based cluster

https://training.hungtran.net/kubernetes/lab-setup/create-kubeamd-based-cluster

### Setup your 3-node cluster

#### 1. Requirements
    - Memory: 4 GB or more of RAM per machine
    - CPUs: At least 2 CPUs on the control plane machine.
    - Internet connectivity for pulling containers required (Private registry can also be used)
    - Full network connectivity between machines in the cluster

#### 2. Google Cloud Shell
- Start your free instance of Cloud Shell from any browser.

- Set a default compute region and compute zone that is near your place:
```
gcloud config set compute/region asia-southeast1
```

- Set a default compute zone:
```
gcloud config set compute/zone asia-southeast1-c
```

- Verification:
```
gcloud config list
[compute]
region = asia-southeast1
zone = asia-southeast1-c
[core]
account = cka.msb.2023@gmail.com
disable_usage_reporting = False
project = red-grid-394709

Your active configuration is: [default]
```

#### 3. Create 2 GCE instances
- VM configuration
```
name: cp1/node[1,2]
family: e2-medium (2vCPU, 4GB)
image: ubuntu20.04 LTS focal
disk: 50GB
```

- Create a control plane node `cp1`
```
gcloud compute instances create cp1 \
--machine-type=e2-medium \
--image=ubuntu-2004-focal-v20240519 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB
```

- Create 3 worker nodes
```
for i in 1 2 ; do
    gcloud compute instances create node${i} \
        --machine-type=e2-medium \
        --image=ubuntu-2004-focal-v20240519 \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size=50GB
done
```

- Allow NodePort
```
gcloud compute firewall-rules create nodeports --allow tcp:30000-40000
```

- Check if VMs have been created
```
gcloud compute instances list
```

- Connect to VMs
```shell
# connect to instance
gcloud compute ssh cp1
gcloud compute ssh node1
gcloud compute ssh node2
```

- Cleanup resources if needed

```
gcloud compute instances delete cp1 node1 node2 --quiet
```

```
gcloud compute firewall-rules delete nodeports
```

### Setup and configure Kubernetes cluster using `kubeadm`

#### 1. Install and configure containerd (all nodes)
- Load required modules at boot
```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

```
sudo modprobe overlay
sudo modprobe br_netfilter
```
- sysctl params required by setup, params persist across reboots
```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

- Apply `sysctl` params without reboot
```
sudo sysctl --system
```

- Install `containerd`
```
sudo apt-get update 
sudo apt-get install -y containerd
```

#### 2. Install Kubernetes packages (all nodes)
- Add Google's apt repository gpg key
```shell
sudo mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

- Update the package list and use apt-cache policy to inspect versions available in the repository
```
sudo apt-get update
apt-cache policy kubelet | head -n 20
```

> [!NOTE]  
> We will start with v1.30.0 instead of the latest version because later in this course, we'll run an upgrade.

- Install v1.30.0 kubernetes packages
```
VERSION=1.30.0
sudo apt-get install -y kubelet=$VERSION-1.1 kubeadm=$VERSION-1.1 kubectl=$VERSION-1.1 
sudo apt-mark hold kubelet kubeadm kubectl containerd
```
- Check the status of kubelet and containerd
```
sudo systemctl status kubelet.service 
sudo systemctl status containerd.service
```

> [!NOTE]  
> The kubelet will enter a crashloop until a cluster is created or the node is joined to an existing cluster.

- Ensure both are set to start when the system starts up
```
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service
```

#### 3. Create cluster (on `cp1`)

- Use kubeadm init to bootstrap the cluster
```
sudo kubeadm init --kubernetes-version=${VERSION} --pod-network-cidr=192.168.0.0/16
```

- Configure the account on the Control Plane Node to have admin access to the API server from a non-privileged account
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

- Create the pod network with Calico
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
```

- Check if all the `system pods` and `calico` pods to change to `Running`. 
```
kubectl get pods -n kube-system
```

- Get a list of our current nodes, just the Control Plane Node should be `Ready`.

```
kubectl get node
```

- Check out the systemd `kubelet` , it's no longer crashlooping because it has static pods to start
```
sudo systemctl status kubelet.service
```

- Let's check out the static pod manifests on the Control Plane Node
```
ls /etc/kubernetes/manifests
```

- And take a closer look at the manifests for the `API server` and `etcd`.
```
sudo more /etc/kubernetes/manifests/etcd.yaml
sudo more /etc/kubernetes/manifests/kube-apiserver.yaml
```

#### 4. Join node to cluster (on `node1`, `node2`)
- Add node to the cluster (with the kubeadm join command generated on CP node)
```
sudo kubeadm join 10.148.0.2:6443 --token xxxxxxx --discovery-token-ca-cert-hash sha256:xxx
```

> [!NOTE]  
> In case you lost the kubeadm join command. You can just create the new one with
>
> `sudo kubeadm token create --print-join-command`

#### 5. Verify cluster status (on CP node)
- Back on Control Plane Node, this will say `NotReady` until the networking pod is created on the new node
```
kubectl get nodes
```

- Watch for the calico pod and the `kube-proxy` to change to `Running` on the newly added nodes
```
kubectl get pod -n kube-system -owide
```

#### 6. Run End-to-end test (on CP)
- Deploy nginx 
```
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

- Verify pod can run
```
kubectl get pods
kubectl get deployments
```
- View logs
```
kubectl logs -f pod-id
```

- Check if service is accessible
```
kubectl expose deployment nginx-deployment --type NodePort --port 80
kubectl get services
```

- Check access
```
curl --head http://node1:<nodeport>

curl --head http://node2:<nodeport>
```

> [!NOTE]  
> It will take time for the calico network to function correctly.

- Cleanup resources after test
```
kubectl delete -f https://k8s.io/examples/application/deployment.yaml
kubectl delete services nginx-deployment
```

#### 7. [optional] Setup terminal (on `cp1`)

```shell
sudo apt-get update
sudo apt-get install -y bash-completion binutils
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc
```
