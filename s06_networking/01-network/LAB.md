# Investigating k8s networking

Get all Nodes and their IP information, INTERNAL-IP is the real IP of the Node

```
kubectl get nodes -o wide

NAME                                       STATUS   ROLES    AGE     VERSION          INTERNAL-IP   EXTERNAL-IP      OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-cluster-1-default-pool-487a6374-lj8l   Ready    <none>   2d23h   v1.16.11-gke.5   10.148.0.10   35.240.171.179   Container-Optimized OS from Google   4.19.112+        docker://19.3.1
gke-cluster-1-default-pool-487a6374-nz29   Ready    <none>   2d23h   v1.16.11-gke.5   10.148.0.9    35.198.236.76    Container-Optimized OS from Google   4.19.112+        docker://19.3.1
gke-cluster-1-default-pool-487a6374-x2nh   Ready    <none>   2d23h   v1.16.11-gke.5   10.148.0.8    34.87.108.113    Container-Optimized OS from Google   4.19.112+        docker://19.3.1
```

Deploy a basic workload, hello-world with 3 replicas.

```
kubectl apply -f Deployment.yaml
```


Verify if a pod has its unique IP address

```
kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE     IP           NODE                                       NOMINATED NODE   READINESS GATES
hello-world-5b76c5697b-7cd48   1/1     Running   0          5m39s   10.48.0.5    gke-cluster-1-default-pool-487a6374-x2nh   <none>           <none>
hello-world-5b76c5697b-8mjn4   1/1     Running   0          5m39s   10.48.1.5    gke-cluster-1-default-pool-487a6374-nz29   <none>           <none>
hello-world-5b76c5697b-cvpcv   1/1     Running   0          5m39s   10.48.2.11   gke-cluster-1-default-pool-487a6374-lj8l   <none>           <none>
```

Access to pod shell and check its networking configuration

```
PODNAME=$(kubectl get pods --selector=app=hello-world -o jsonpath='{ .items[0].metadata.name }')

kubectl exec -it $PODNAME -- ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
3: eth0@if8: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1460 qdisc noqueue state UP 
    link/ether 26:e3:bb:fe:f1:cc brd ff:ff:ff:ff:ff:ff
    inet 10.48.0.5/24 brd 10.48.0.255 scope global eth0
       valid_lft forever preferred_lft forever

```

SSH to the worker node and check the network information

```
ip addr

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1460 qdisc mq state UP group default qlen 1000
    link/ether 42:01:0a:94:00:0a brd ff:ff:ff:ff:ff:ff
    inet 10.148.0.10/32 scope global dynamic eth0
       valid_lft 3500sec preferred_lft 3500sec
    inet6 fe80::4001:aff:fe94:a/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:f8:56:08:2c brd ff:ff:ff:ff:ff:ff
    inet 169.254.123.1/24 brd 169.254.123.255 scope global docker0
       valid_lft forever preferred_lft forever
4: cbr0: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1460 qdisc htb state UP group default qlen 1000
    link/ether 02:61:37:4a:3c:09 brd ff:ff:ff:ff:ff:ff
    inet 10.48.2.1/24 brd 10.48.2.255 scope global cbr0
       valid_lft forever preferred_lft forever
    inet6 fe80::61:37ff:fe4a:3c09/64 scope link 
       valid_lft forever preferred_lft forever
5: veth016d847c@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1460 qdisc noqueue master cbr0 state UP group default 
    link/ether c2:3c:99:13:c9:d5 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::c03c:99ff:fe13:c9d5/64 scope link 
       valid_lft forever preferred_lft forever
6: vethd910d1ef@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1460 qdisc noqueue master cbr0 state UP group default 
    link/ether 16:81:fc:23:6d:33 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::1481:fcff:fe23:6d33/64 scope link 
       valid_lft forever preferred_lft forever
8: vethdc6beca3@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1460 qdisc noqueue master cbr0 state UP group default 
    link/ether 7e:77:11:cc:9f:9f brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::7c77:11ff:fecc:9f9f/64 scope link 
       valid_lft forever preferred_lft forever
14: veth79a85604@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1460 qdisc noqueue master cbr0 state UP group default 
    link/ether 8a:98:f0:e7:67:29 brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::8898:f0ff:fee7:6729/64 scope link 
       valid_lft forever preferred_lft forever
```

```
route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         10.148.0.1      0.0.0.0         UG    1024   0        0 eth0
10.48.2.0       0.0.0.0         255.255.255.0   U     0      0        0 cbr0
10.148.0.1      0.0.0.0         255.255.255.255 UH    1024   0        0 eth0
169.254.123.0   0.0.0.0         255.255.255.0   U     0      0        0 docker0   



brctl show
bridge name     bridge id               STP enabled     interfaces
cbr0            8000.0261374a3c09       no              veth016d847c
                                                        veth79a85604
                                                        vethd910d1ef
                                                        vethdc6beca3
docker0         8000.0242f856082c       no  
```

Exploring cluster DNS
Get k8s service in kube-system

```
kubectl get service --namespace kube-system
NAME                        TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP   10.0.20.20    <none>        8000/TCP        35m
kube-dns                    ClusterIP   10.0.0.10     <none>        53/UDP,53/TCP   35m
kubernetes-dashboard        ClusterIP   10.0.50.224   <none>        443/TCP         35m
metrics-server              ClusterIP   10.0.61.133   <none>        443/TCP         35m      
```

Get detail info about CoreDNS deployment

```
kubectl describe deployment coredns --namespace kube-system
```

Discover the CoreDNS configuration and default forwarder

```
kubectl get configmaps --namespace kube-system coredns -o yaml
```

Configure Pod DNS client Configuration

```
kubectl apply -f DeploymentCustomDns.yaml
```


Check the DNS configuration of the normal pod and custom pod

```
CUSTOM_PODNAME=$(kubectl get pods --selector=app=hello-world-customdns -o jsonpath='{ .items[0].metadata.name }')

kubectl exec -it $CUSTOM_PODNAME -- cat /etc/resolv.conf
nameserver 9.9.9.9

PODNAME=$(kubectl get pods --selector=app=hello-world -o jsonpath='{ .items[0].metadata.name }')

kubectl exec -it $PODNAME -- cat /etc/resolv.conf
nameserver 10.0.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:
```

DNS discovering

Run a busybox pod in the same namespace and test DNS resolving

```
kubectl run -it --rm bb --image busybox -- bin/sh
/ # nslookup hello-world
Server:         10.0.0.10
Address:        10.0.0.10:53

Name:   hello-world.default.svc.cluster.local
Address: 10.0.222.248
```

Run another busybox pod in a different namespace

```
kubectl create ns myns
```

```
kubectl run -n myns -it --rm bb1 --image busybox -- bin/sh
/ # nslookup hello-world
Server:         10.0.0.10
Address:        10.0.0.10:53
```

** server can't find hello-world.myns.svc.cluster.local: NXDOMAIN

/ # nslookup hello-world.default.svc.cluster.local
Server:         10.0.0.10
Address:        10.0.0.10:53
