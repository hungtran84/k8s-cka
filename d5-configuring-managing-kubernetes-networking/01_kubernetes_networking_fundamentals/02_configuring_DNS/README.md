### Investigating the Cluster DNS Service
- It's Deployed as a Service in the cluster with a Deployment in the kube-system namespace

```
kubectl get service --namespace kube-system
```

- Two `Replicas`, `Args` injecting the location of the config file which is backed by `ConfigMap` mounted as a Volume.
```
kubectl describe deployment coredns --namespace kube-system

Name:                   coredns
Namespace:              kube-system
CreationTimestamp:      Mon, 28 Aug 2023 17:59:35 +0000
Labels:                 k8s-app=kube-dns
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               k8s-app=kube-dns
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 25% max surge
Pod Template:
  Labels:           k8s-app=kube-dns
  Service Account:  coredns
  Containers:
   coredns:
    Image:       registry.k8s.io/coredns/coredns:v1.10.1
    Ports:       53/UDP, 53/TCP, 9153/TCP
    Host Ports:  0/UDP, 0/TCP, 0/TCP
    Args:
      -conf
      /etc/coredns/Corefile
    Limits:
      memory:  170Mi
    Requests:
      cpu:        100m
      memory:     70Mi
    Liveness:     http-get http://:8080/health delay=60s timeout=5s period=10s #success=1 #failure=5
    Readiness:    http-get http://:8181/ready delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:
      /etc/coredns from config-volume (ro)
  Volumes:
   config-volume:
    Type:               ConfigMap (a volume populated by a ConfigMap)
    Name:               coredns
    Optional:           false
  Priority Class Name:  system-cluster-critical
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   coredns-5d78c9869d (2/2 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  15m   deployment-controller  Scaled up replica set coredns-5d78c9869d to 2
```
 
### Configuring CoreDNS to use custom Forwarders, spaces not tabs!
- Defaults use the nodes DNS Servers for fowarders.
Replaces forward . `/etc/resolv.conf` with forward . `1.1.1.1`.
Add a conditional domain forwarder for a specific domain.
ConfigMap will take a second to update the mapped file and the config to be reloaded

```
kubectl apply -f CoreDNSConfigCustom.yaml --namespace kube-system
```

- How will we know when the CoreDNS configuration file is updated in the pod?
You can tail the log looking for the reload the configuration file, this can take a minute or two.
Also look for any errors post configuration. Seeing `No files matching import glob pattern: custom/*.override` is normal.
```
kubectl logs --namespace kube-system --selector 'k8s-app=kube-dns' --follow 
```

- Run some DNS queries against the kube-dns service cluster ip to ensure everything works...

```
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{ .spec.clusterIP }')
nslookup hungtran.com $SERVICEIP
```

- Let's put the default configuration back, using . forward /etc/resolv.conf 
```
kubectl apply -f CoreDNSConfigDefault.yaml --namespace kube-system
```


### Configuring Pod DNS client Configuration
```
kubectl apply -f DeploymentCustomDns.yaml
```

- Let's check the DNS configuration of a Pod created with that configuration
```
PODNAME=$(kubectl get pods --selector=app=hello-world-customdns -o jsonpath='{ .items[0].metadata.name }')
echo $PODNAME
kubectl exec -it $PODNAME -- cat /etc/resolv.conf
```

- Clean up our resources
```
kubectl delete -f DeploymentCustomDns.yaml
```


#### Get a pods DNS A record and a Services A record
- Create a deployment and a service
```
kubectl apply -f Deployment.yaml
```

- Get the pods and their IP addresses
```
kubectl get pods -o wide
```

- Get the address of our DNS Service again...just in case
```
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{ .spec.clusterIP }')
```

- For one of the pods replace the dots in the IP address with dashes for example 192.168.206.68 becomes 192-168-206-68.
```
nslookup 192-168-206-68.default.pod.cluster.local $SERVICEIP
```

- Our Services also get DNS A records.
```
kubectl get service 
nslookup hello-world.default.svc.cluster.local $SERVICEIP
```

- Clean up our resources
```
kubectl delete -f Deployment.yaml
```
