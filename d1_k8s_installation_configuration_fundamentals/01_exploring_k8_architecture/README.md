# Kubernetes Playground

Use `Play-with-kubernetes` to quickly setup a 3-nodes cluster and deploy a sample app

## Access Play-with-Kubernetes at https://labs.play-with-k8s.com/

## Add 3 instances

## Setup kubeadm-based cluster in Node1

- Initialize the cluster

```
[node1 ~]$  kubeadm init --apiserver-advertise-address $(hostname -i) --pod-network-cidr 10.5.0.0/16

Initializing machine ID from random generator.
...
You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.13:6443 --token hfumzn.t10lxlfwh48qljp4 \
        --discovery-token-ca-cert-hash sha256:xxx
...
```

- Deploy a simple pod network using `kuberouter`

```
kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
```

- Check master node is up & running

```
[node1 ~]$ kubectl get node
NAME    STATUS   ROLES           AGE   VERSION
node1   Ready    control-plane   12m   v1.27.2
```

## Connect nodes to the cluster (run on both Node2 & Node3)

```
# Using the generated `kubeadm join` in master node
kubeadm join 192.168.0.13:6443 --token hfumzn.t10lxlfwh48qljp4 --discovery-token-ca-cert-hash sha256:xxx
```

## Verify the status of the cluster

```
[node1 ~]$ kubectl get no
NAME    STATUS   ROLES           AGE   VERSION
node1   Ready    control-plane   79s   v1.27.2
node2   Ready    <none>          23s   v1.27.2
node3   Ready    <none>          10s   v1.27.2
```

## Deploy nginx app

```
kubectl apply -f https://raw.githubusercontent.com/hungtran84/k8s-cka/master/d1_k8s_installation_configuration_fundamentals/01_exploring_k8_architecture/nginx-app.yaml
```

## Access nginx web app

```
curl http://localhost:30007

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```