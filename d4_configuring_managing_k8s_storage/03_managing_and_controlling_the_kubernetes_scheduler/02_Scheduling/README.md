## Using `Affinity` and `Anti-Affinity` to schedule Pods to Nodes

### Using `Affinity`
- Let's start off with a deployment of web and cache pods.
`Affinity`: We want to always have a cache pod co-located with a Web Pod on the same node.
```
kubectl apply -f deployment-affinity.yaml
deployment.apps/hello-world-web created
deployment.apps/hello-world-cache created
```

- Let's check out the labels on the nodes, look for `kubernetes.io/hostname` which we're using for our `topologykey`
```
kubectl describe nodes gke-gke-test-default-pool-03d0c6b2-bfk0 | grep kubernetes.io/hostname

kubernetes.io/hostname=gke-gke-test-default-pool-03d0c6b2-bfk0
```

- We can see that web and cache are both on the name node
```
kubectl get pods -o wide 

NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-cache-687f96b56-c9dpk   1/1     Running   0          2d    10.28.0.104   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-58fbb7b784-mmjwn    1/1     Running   0          2d    10.28.0.103   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
```

- If we scale the web deployment.
We'll still get spread across nodes in the `ReplicaSet`, so we don't need to enforce that with `affinity`.
```
kubectl scale deployment hello-world-web --replicas=2
deployment.apps/hello-world-web scaled

kubectl get pods -o wide 
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-cache-687f96b56-wjcpv   1/1     Running   0          19s   10.28.0.110   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-58fbb7b784-fbn7z    1/1     Running   0          5s    10.28.0.111   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-58fbb7b784-k7qkq    1/1     Running   0          20s   10.28.0.109   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
```

- Then when we scale the cache deployment, it will get scheduled to the same node as the other web server.
```
kubectl scale deployment hello-world-cache --replicas=2
deployment.apps/hello-world-cache scaled

kubectl get pods -o wide 
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-cache-687f96b56-r5rth   1/1     Running   0          13s   10.28.0.112   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-cache-687f96b56-wjcpv   1/1     Running   0          55s   10.28.0.110   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-58fbb7b784-fbn7z    1/1     Running   0          41s   10.28.0.111   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-58fbb7b784-k7qkq    1/1     Running   0          56s   10.28.0.109   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
```

> **Hometask**
> How to distribute Web and Cache pods among 3 nodes while maintaining affinity?

- Clean up the resources from these deployments
```
kubectl delete -f deployment-affinity.yaml
deployment.apps "hello-world-web" deleted
deployment.apps "hello-world-cache" deleted
```

### Using `anti-affinity` 
- Now, let's test out `anti-affinity`, deploy web and cache again. 
But this time we're going to make sure that no more than 1 web pod is on each node with `anti-affinity`
```
kubectl apply -f deployment-antiaffinity.yaml
deployment.apps/hello-world-web created
deployment.apps/hello-world-cache created

kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-cache-687f96b56-lj47d   1/1     Running   0          13s   10.28.0.114   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-5c487f74cd-kvlck    1/1     Running   0          13s   10.28.0.113   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
```

- Now let's scale the replicas in the web and cache deployments
```
kubectl scale deployment hello-world-web --replicas=4
deployment.apps/hello-world-web scaled
```

- One Pod will go Pending because we can have only 1 Web Pod per node when using 
`requiredDuringSchedulingIgnoredDuringExecution` in our `antiaffinity` rule
```
kubectl get pods -o wide --selector app=hello-world-web
NAME                               READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-web-5c487f74cd-b8fqj   1/1     Running   0          16s   10.28.2.53    gke-gke-test-default-pool-03d0c6b2-bfk0   <none>           <none>
hello-world-web-5c487f74cd-kvlck   1/1     Running   0          66s   10.28.0.113   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-5c487f74cd-ngl59   1/1     Running   0          16s   10.28.1.52    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-web-5c487f74cd-s7d6k   0/1     Pending   0          16s   <none>        <none>                                    <none>           <none>
```

- To `fix` this we can change the scheduling rule to `preferredDuringSchedulingIgnoredDuringExecution`.
Also going to set the number of replicas to 4
```
kubectl apply -f deployment-antiaffinity-corrected.yaml
deployment.apps/hello-world-web configured
deployment.apps/hello-world-cache unchanged

kubectl scale deployment hello-world-web --replicas=4
deployment.apps/hello-world-web scaled
```

- Now we'll have 4 pods up an running, but doesn't the scheduler already ensure replicaset spread? Yes!
```
kubectl get pods -o wide --selector app=hello-world-web
NAME                               READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-web-6754df6894-6vgg6   1/1     Running   0          44s   10.28.1.53    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-web-6754df6894-9qt6g   1/1     Running   0          24s   10.28.0.116   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-web-6754df6894-bmt7j   1/1     Running   0          24s   10.28.2.54    gke-gke-test-default-pool-03d0c6b2-bfk0   <none>           <none>
hello-world-web-6754df6894-qtsdv   1/1     Running   0          24s   10.28.0.115   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
```

- Let's clean up the resources
```
kubectl delete -f deployment-antiaffinity-corrected.yaml
deployment.apps "hello-world-web" deleted
deployment.apps "hello-world-cache" deleted
```

### Controlling Pods placement with `Taints` and `Tolerations`
- Let's add a `Taint` to the first node
```
kubectl taint nodes gke-gke-test-default-pool-03d0c6b2-bfk0 key=MyTaint:NoSchedule
node/gke-gke-test-default-pool-03d0c6b2-bfk0 tainted
```

- We can see the taint at the node level, look at the `Taints` section
```
kubectl describe node gke-gke-test-default-pool-03d0c6b2-bfk0 | grep Taint

Taints:             key=MyTaint:NoSchedule
```

- Let's create a deployment with `3` replicas
```
kubectl apply -f deployment.yaml
deployment.apps/hello-world created
```

- We can see Pods get placed on the non tainted nodes
```
kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-68c787c876-mgb2k   1/1     Running   0          22s   10.28.1.54    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-68c787c876-ss5fl   1/1     Running   0          22s   10.28.0.118   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-68c787c876-v752b   1/1     Running   0          22s   10.28.0.117   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
```

- But if we add a deployment with a `Toleration`...
```
kubectl apply -f deployment-tolerations.yaml
deployment.apps/hello-world-tolerations created
```

- We can see that Pods are spread out over 3 nodes.
```
kubectl get pods -o wide
NAME                                       READY   STATUS    RESTARTS   AGE     IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-68c787c876-mgb2k               1/1     Running   0          2m22s   10.28.1.54    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-68c787c876-ss5fl               1/1     Running   0          2m22s   10.28.0.118   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-68c787c876-v752b               1/1     Running   0          2m22s   10.28.0.117   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-tolerations-59ff95b965-8sflv   1/1     Running   0          75s     10.28.2.55    gke-gke-test-default-pool-03d0c6b2-bfk0   <none>           <none>
hello-world-tolerations-59ff95b965-mttsr   1/1     Running   0          75s     10.28.1.55    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-tolerations-59ff95b965-t9pb7   1/1     Running   0          75s     10.28.0.119   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
```

- Remove our `Taint`
```
kubectl taint nodes gke-gke-test-default-pool-03d0c6b2-bfk0 key:NoSchedule-
node/gke-gke-test-default-pool-03d0c6b2-bfk0 untainted
```

- Clean up after our demo
```
kubectl delete -f deployment-tolerations.yaml
kubectl delete -f deployment.yaml
```

### Using `Labels` to Schedule `Pods` to `Nodes`

- Query our labels to see if the `disk` and `hardware` labels are already in place.
```
kubectl get node -L disk,hardware
NAME                                      STATUS   ROLES    AGE   VERSION           DISK        HARDWARE
gke-gke-test-default-pool-03d0c6b2-bfk0   Ready    <none>   9d    v1.27.3-gke.100   local_ssd   
gke-gke-test-default-pool-03d0c6b2-n7l2   Ready    <none>   9d    v1.27.3-gke.100               local_gpu
gke-gke-test-default-pool-03d0c6b2-sv8f   Ready    <none>   9d    v1.27.3-gke.100               
```

- Otherwise, label our nodes with `disk=local_ssd` and `hardware=local_gpu`
```shell
# node 1
kubectl label node gke-gke-test-default-pool-03d0c6b2-bfk0 disk=local_ssd

# node 2
kubectl label node gke-gke-test-default-pool-03d0c6b2-n7l2 hardware=local_gpu
```

- Create 3 Pods, two using `nodeSelector`, one without.
```
kubectl apply -f DeploymentsToNodes.yaml
deployment.apps/hello-world-gpu created
deployment.apps/hello-world-ssd created
deployment.apps/hello-world created
```

- View the scheduling of the pods in the cluster.
```
kubectl get node -L disk,hardware
NAME                                      STATUS   ROLES    AGE   VERSION           DISK        HARDWARE
gke-gke-test-default-pool-03d0c6b2-bfk0   Ready    <none>   9d    v1.27.3-gke.100   local_ssd   
gke-gke-test-default-pool-03d0c6b2-n7l2   Ready    <none>   9d    v1.27.3-gke.100               local_gpu
gke-gke-test-default-pool-03d0c6b2-sv8f   Ready    <none>   9d    v1.27.3-gke.100    

kubectl get pods -o wide
NAME                               READY   STATUS    RESTARTS   AGE   IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-68c787c876-wbgxq       1/1     Running   0          25s   10.28.0.120   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-gpu-7796849f94-nsspz   1/1     Running   0          26s   10.28.1.56    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-ssd-6dfb7cf77-m59mg    1/1     Running   0          26s   10.28.2.56    gke-gke-test-default-pool-03d0c6b2-bfk0   <none>           <none>
```

- If we scale this Deployment, all new Pods will go onto the node with the GPU label
```
kubectl scale deployment hello-world-gpu --replicas=3
deployment.apps/hello-world-gpu scaled

kubectl get pods -o wide
NAME                               READY   STATUS    RESTARTS   AGE    IP            NODE                                      NOMINATED NODE   READINESS GATES
hello-world-68c787c876-wbgxq       1/1     Running   0          102s   10.28.0.120   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-gpu-7796849f94-6f2xn   1/1     Running   0          10s    10.28.1.58    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-gpu-7796849f94-bxp4v   1/1     Running   0          10s    10.28.1.57    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-gpu-7796849f94-nsspz   1/1     Running   0          103s   10.28.1.56    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
hello-world-ssd-6dfb7cf77-m59mg    1/1     Running   0          103s   10.28.2.56    gke-gke-test-default-pool-03d0c6b2-bfk0   <none>           <none>
```

- If we scale this Deployment, all new Pods will go onto the node with the SSD label
```
kubectl scale deployment hello-world-ssd --replicas=3 
kubectl get pods -o wide
```

- If we scale this Deployment, all new Pods will likely go onto the node without the labels to keep the load balanced
```
kubectl scale deployment hello-world --replicas=3
kubectl get pods -o wide 
```

- If we go beyond that, it will use all node to keep load even globally
```
kubectl scale deployment hello-world --replicas=10
kubectl get pods -o wide 
```

- Clean up when we're finished
```
kubectl delete deployments.apps hello-world
kubectl delete deployments.apps hello-world-gpu
kubectl delete deployments.apps hello-world-ssd
```