## Examining System Pods and their Controllers

- Inside the `kube-system` namespace, there's a collection of controllers supporting parts of the cluster's control plane.
How'd they get started since there's no cluster when they need to come online? `Static Pod Manifests` are the answer.

```
kubectl get --namespace kube-system all

NAME                                READY   STATUS    RESTARTS   AGE
pod/coredns-5d78c9869d-6626t        1/1     Running   0          13m
pod/coredns-5d78c9869d-pnhkq        1/1     Running   0          13m
pod/etcd-node1                      1/1     Running   0          13m
pod/kube-apiserver-node1            1/1     Running   0          13m
pod/kube-controller-manager-node1   1/1     Running   0          13m
pod/kube-proxy-xflzb                1/1     Running   0          13m
pod/kube-router-ndmt8               1/1     Running   0          13m
pod/kube-scheduler-node1            1/1     Running   0          14m

NAME               TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
service/kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   14m

NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/kube-proxy    1         1         1       1            1           kubernetes.io/os=linux   14m
daemonset.apps/kube-router   1         1         1       1            1           <none>                   13m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/coredns   2/2     2            2           14m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/coredns-5d78c9869d   2         2         2       13m
```

- Let's look more closely at one of those deployments, requiring 2 pods up and runnning at all times.
```
kubectl get --namespace kube-system deployments coredns

NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   2/2     2            2           14m
```

- `Daemonset` Pods run on every node in the cluster by default, as new nodes are added these will be deployed to those nodes.
There's a Pod for our Pod network, eg. `kube-router` and one for the `kube-proxy`.
```
kubectl get --namespace kube-system daemonset

NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-proxy    1         1         1       1            1           kubernetes.io/os=linux   15m
kube-router   1         1         1       1            1           <none>                   15m
```

- Increase to 4 nodes, we'll see the DaemonSet pods also increase to 4
```
kubectl get nodes
NAME    STATUS   ROLES           AGE    VERSION
node1   Ready    control-plane   2m6s   v1.27.2
node2   Ready    <none>          56s    v1.27.2
node3   Ready    <none>          52s    v1.27.2
node4   Ready    <none>          49s    v1.27.2
node5   Ready    <none>          45s    v1.27.2

kubectl get --namespace kube-system daemonset
NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-proxy    5         5         5       5            5           kubernetes.io/os=linux   104s
kube-router   5         5         5       5            5           <none>                   49s
```