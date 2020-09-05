# Node Cordoning

- Drain node in preparation for maintenance.
The given node will be marked unschedulable to prevent new pods from arriving. and evict pods
When you are ready to put the node back into service, use kubectl uncordon, which will make the node schedulable again.
Let's create a deployment with three replicas

```
kubectl apply -f deployment.yaml
```

- Pods spread out evenly across the nodes

```
kubectl get pods -o wide
```

- Let's cordon c1-node3

```
kubectl cordon c1-node3
```

- That won't evict any pods...

```
kubectl get pods -o wide
```

- Let's drain (remove) the Pods from node3..

```
kubectl drain gke-cluster-1-default-pool-990b49f7-bzft
```

- Let's try that again since daemonsets aren't scheduled we need to work around them.

```
kubectl drain gke-cluster-1-default-pool-990b49f7-bzft --ignore-daemonsets
```

- Now all the workload is on node 1 and 2

```
kubectl get pods -o wide
```

- We can uncordon c1-node3, but nothing will get scheduled there until there's an event like a scaling operation or an eviction.

```
kubectl uncordon gke-cluster-1-default-pool-990b49f7-bzft
kubectl get pods -o wide
```

- So let's scale that Deployment and see where they get scheduled...

```
kubectl scale deployment hello-world --replicas=4
```

- All three get scheduled to the cordoned node

```
kubectl get pods -o wide
```

- Clean up this demo...

```
kubectl delete deployment hello-world
```
 