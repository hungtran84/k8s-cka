## Working with cluster

- Listing and inspecting your cluster...helpful for knowing which cluster is your current context

```
kubectl cluster-info
```

- Review status, roles and versions
```
kubectl get nodes
```

- You can add an output modifier to get to *get* more information about a resource

```
kubectl get nodes -o wide
```

- Let's get a list of pods...but there isn't any running.

```
kubectl get pods 
```

- True, but let's get a list of system pods. A namespace is a way to group resources together.
```
kubectl get pods --namespace kube-system
```

- Let's get additional information about each pod. 
```
kubectl get pods --namespace kube-system -o wide
```

- Now let's get a list of everything that's running in all namespaces. In addition to pods, we see services, daemonsets, deployments and replicasets

```
kubectl get all --all-namespaces | more
```

- Asking kubernetes for the resources it knows about. Let's look at the headers in each column. Name, Alias/shortnames, API Version 
is the resources in a namespace (namespaced resources), for example StorageClass isn't and is available to all namespaces and finally Kind...this is the object type.

```
kubectl api-resources | more
```

- You'll soon find your favorite alias
```
kubectl get no
```

- We can easily filter using group
```
kubectl api-resources | grep pod
```

- Explain an indivdual resource in detail
```
kubectl explain pod | more 
kubectl explain pod.spec | more 
kubectl explain pod.spec.containers | more 
kubectl explain pod --recursive | more 
```


- Let's take a closer look at our nodes using Describe. Check out Name, Taints, Conditions, Addresses, System Info, Non-Terminated Pods, and Events

```
kubectl describe nodes <cp_node> | more 
kubectl describe nodes <node> | more
```

- Use `-h` or `--help` to find help
```
kubectl -h | more
kubectl get -h | more
kubectl create -h | more
```

- Ok, so now that we're tired of typing commands out, let's enable 
bash auto-complete of our kubectl commands
```
sudo apt-get install -y bash-completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
kubectl g[tab][tab] po[tab][tab] --all[tab][tab]
```