###  Node Cordoning
- Let's create a deployment with 3 replicas
```
kubectl apply -f deployment.yaml
```

- Pods spread out evenly across the nodes
```
kubectl get pods -o wide
```

- Let's cordon node 3
```
kubectl cordon gke-gke-test-default-pool-03d0c6b2-sv8f
node/gke-gke-test-default-pool-03d0c6b2-sv8f cordoned
```

- That won't evict any pods...
```
kubectl get pods -o wide
```

- But if I scale the deployment
```
kubectl scale deployment hello-world --replicas=6
```

- Node 3 won't get any new pods, one of the other Nodes will get an extra Pod here.
```
kubectl get pods -o wide
```

- Let's `drain` the Pods from node3...
```
kubectl drain gke-gke-test-default-pool-03d0c6b2-sv8f

error: unable to drain node "gke-gke-test-default-pool-03d0c6b2-sv8f" due to error:[cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): gmp-system/collector-mhmw7, kube-system/fluentbit-gke-lnb67, kube-system/gke-metrics-agent-rsv75, kube-system/pdcsi-node-d4fdl, cannot delete Pods with local storage (use --delete-emptydir-data to override): gmp-system/rule-evaluator-5884dd44d8-m8q52, kube-system/metrics-server-v0.5.2-6bf74b5d5f-jplrd], continuing command...
There are pending nodes to be drained:
 gke-gke-test-default-pool-03d0c6b2-sv8f
cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): gmp-system/collector-mhmw7, kube-system/fluentbit-gke-lnb67, kube-system/gke-metrics-agent-rsv75, kube-syst
```

- Let's try that again since `daemonsets` aren't scheduled we need to work around them.
```
kubectl drain gke-gke-test-default-pool-03d0c6b2-sv8f --ignore-daemonsets

error: unable to drain node "gke-gke-test-default-pool-03d0c6b2-sv8f" due to error:cannot delete Pods with local storage (use --delete-emptydir-data to override): gmp-system/rule-evaluator-5884dd44d8-m8q52, kube-system/metrics-server-v0.5.2-6bf74b5d5f-jplrd, continuing command...
There are pending nodes to be drained:
 gke-gke-test-default-pool-03d0c6b2-sv8f
cannot delete Pods with local storage (use --delete-emptydir-data to override): gmp-system/rule-evaluator-5884dd44d8-m8q52, kube-system/metrics-server-v0.5.2-6bf74b5d5f-jplrd
```

- Keep working around by delete local storage (in case of GKE cluster)
```
kubectl drain gke-gke-test-default-pool-03d0c6b2-sv8f --ignore-daemonsets --delete-emptydir-data

node/gke-gke-test-default-pool-03d0c6b2-sv8f already cordoned
Warning: ignoring DaemonSet-managed Pods: gmp-system/collector-mhmw7, kube-system/fluentbit-gke-lnb67, kube-system/gke-metrics-agent-rsv75, kube-system/pdcsi-node-d4fdl
evicting pod kube-system/metrics-server-v0.5.2-6bf74b5d5f-jplrd
evicting pod default/hello-world-68c787c876-fm596
evicting pod gmp-system/rule-evaluator-5884dd44d8-m8q52
evicting pod gmp-system/gmp-operator-844674854c-z6696
evicting pod kube-system/konnectivity-agent-64c5b99b76-9lwsv
pod/hello-world-68c787c876-fm596 evicted
pod/rule-evaluator-5884dd44d8-m8q52 evicted
pod/metrics-server-v0.5.2-6bf74b5d5f-jplrd evicted
pod/konnectivity-agent-64c5b99b76-9lwsv evicted
pod/gmp-operator-844674854c-z6696 evicted
node/gke-gke-test-default-pool-03d0c6b2-sv8f drained
```

- Now all the workload is on node1 and 2
```
kubectl get pods -o wide
```

- We can `uncordon` node3, but nothing (except system and add-ons pods) will get scheduled there until there's an event like a scaling operation or an eviction.
Something that will cause pods to get created.
```
kubectl uncordon gke-gke-test-default-pool-03d0c6b2-sv8f
node/gke-gke-test-default-pool-03d0c6b2-sv8f uncordoned
```

- So let's scale that Deployment and see where they get scheduled...
```
kubectl scale deployment hello-world --replicas=9
```

- All three get scheduled to the cordoned node
```
kubectl get pods -o wide
```

- Clean up resources
```
kubectl delete deployment hello-world
```

### Manually scheduling a Pod by specifying `nodeName` that match yours.
```
kubectl apply -f pod.yaml
```

- Our Pod should be on node3
```
kubectl get pod -o wide
```

- Let's delete our pod, since there's no controller it won't get recreated
```
kubectl delete pod hello-world-pod
 ```

- Now let's cordon node3 again
```
kubectl cordon gke-gke-test-default-pool-03d0c6b2-sv8f
```

- And try to recreate our pod
```
kubectl apply -f pod.yaml
```

- You can still place a pod on the node since the Pod isn't getting 'scheduled', status is SchedulingDisabled
kubectl get pod -o wide

- Can't remove the unmanaged Pod either since it's not managed by a Controller and won't get restarted
```
kubectl drain gke-gke-test-default-pool-03d0c6b2-sv8f --ignore-daemonsets 

error: unable to drain node "gke-gke-test-default-pool-03d0c6b2-sv8f" due to error:cannot delete Pods declare no controller (use --force to override): default/hello-world-pod, continuing command...
There are pending nodes to be drained:
 gke-gke-test-default-pool-03d0c6b2-sv8f
cannot delete Pods declare no controller (use --force to override): default/hello-world-pod
```

- Let's clean up our demo, delete our pod and uncordon the node
```
kubectl delete pod hello-world-pod 
kubectl uncordon gke-gke-test-default-pool-03d0c6b2-sv8f
```
