## Finding scheduling information
- Let's create a deployment with 3 replicas
```
kubectl apply -f deployment.yaml
deployment.apps/hello-world created
```

- Pods spread out evenly across the `Nodes` due to our scoring functions for selector spread during Scoring.
```
kubectl get pods -o wide
```

- We can look at the Pods events to see the scheduler making its choice
```
kubectl describe pods 
```

- If we scale our deployment to `6`
```
kubectl scale deployment hello-world --replicas=6
deployment.apps/hello-world scaled
```

- We can see that the scheduler works to keep load even across the nodes.
```
kubectl get pods -o wide
```
#We can see the nodeName populated for this node
```
kubectl get pods hello-world-[tab][tab] -o yaml

...
  nodeName: gke-gke-test-default-pool-03d0c6b2-bfk0
...
```

- Clean up resources
```
kubectl delete deployment hello-world
deployment.apps "hello-world" deleted
```

## Scheduling Pods with resource requests. 
- Start a watch, the pods will go from `Pending`->`ContainerCreating`->`Running`.
Each pod has a 1 core CPU request.
```
kubectl get pods --watch &

kubectl apply -f requests.yaml
hello-world-requests-856cf9b988-xdvb2   0/1     Pending             0          0s
hello-world-requests-856cf9b988-pvffz   0/1     ContainerCreating   0          0s
hello-world-requests-856cf9b988-ghwr4   0/1     Pending             0          0s
hello-world-requests-856cf9b988-xdvb2   0/1     Pending             0          0s
hello-world-requests-856cf9b988-ghwr4   0/1     Pending             0          0s
hello-world-requests-856cf9b988-ghwr4   0/1     ContainerCreating   0          0s
hello-world-requests-856cf9b988-xdvb2   0/1     ContainerCreating   0          0s
hello-world-requests-856cf9b988-pvffz   1/1     Running             0          1s
hello-world-requests-856cf9b988-xdvb2   1/1     Running             0          2s
hello-world-requests-856cf9b988-ghwr4   1/1     Running             0          2s
```
- We created 2 pods, one on each node
```
kubectl get pods -o wide
```

- Let's scale our deployment to 6 replica.  These pods will stay pending.  Some pod names may be repeated.
```
kubectl scale deployment hello-world-requests --replicas=6

hello-world-requests-7578c79cb4-t68ql   0/1     Pending             0          0s
hello-world-requests-7578c79cb4-fnvkr   0/1     Pending             0          0s
hello-world-requests-7578c79cb4-rs2p6   0/1     ContainerCreating   0          0s
hello-world-requests-7578c79cb4-t68ql   0/1     Pending             0          0s
hello-world-requests-7578c79cb4-rs2p6   1/1     Running             0          2s
hello-world-requests-7578c79cb4-t68ql   0/1     Pending             0          2s
hello-world-requests-7578c79cb4-fnvkr   0/1     Pending             0          2s
```

- We see Pods are pending, why?
```
kubectl get pods -o wide
kubectl get pods -o wide | grep Pending
```

- Let's look at why the Pod is `Pending`, check out the Pod's events...
```
kubectl describe pod hello-world-requests-7578c79cb4-fnvkr

Events:
  Type     Reason             Age                  From                Message
  ----     ------             ----                 ----                -------
  Warning  FailedScheduling   108s (x2 over 110s)  default-scheduler   0/3 nodes are available: 3 Insufficient cpu. preemption: 0/3 nodes are available: 3 No preemption victims found for incoming pod..
  Normal   NotTriggerScaleUp  108s                 cluster-autoscaler  pod didn't trigger scale-up:
```

- Clean up after this demo
```
kubectl delete deployment hello-world-requests

- Stop the watch
```
fg
ctrl+c
```
