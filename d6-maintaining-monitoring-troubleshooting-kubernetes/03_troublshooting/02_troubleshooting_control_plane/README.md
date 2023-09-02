## Control Plane Pods Stopped
- Break the CP node to simulate the node failure
```
cd d6-maintaining-monitoring-troubleshooting-kubernetes/03_troublshooting
./2-TroubleshootingControlPlaneBreakStuff-1.sh
```

- Let's check the status of our control plane pods, refused?
It can take a bit to break the control plane, wait until it connection to server was refused
```
kubectl get pods --namespace kube-system
```

- Let's ask our container runtime, what's up, well there's pods running on this node, but no control plane pods.
That's your clue, no control plane pods running. What starts up the control plane pods? static pod manifests?
```
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps
```

- Let's check config.yaml for the location of the static pod manifests.
Look for `staticPodPath`.
Do the yaml files exist at that location?
```
sudo more /var/lib/kubelet/config.yaml
```

- The directory doesn't exist...
```
sudo ls -laR /etc/kubernetes/manifests
````

- Let's look up one directory
```
sudo ls -la /etc/kubernetes/
```

We could update `config.yaml` to point to this path or rename it to put the manifests in the configured location.
The `kubelet` will find these manifests and launch the pods again.
```
sudo mv /etc/kubernetes/manifests.wrong /etc/kubernetes/manifests
sudo ls /etc/kubernetes/manifests/
```

- Check the container runtime to ensure the pods are started. We can see they were created and running just a few seconds ago
```
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps
```

- Let's ask kubernetes whats it thinks...
```
kubectl get pods -n kube-system 
```


## Troubleshooting control plane failure, user Pods are all pending.
- Break the CP node
```
cd d6-maintaining-monitoring-troubleshooting-kubernetes/03_troublshooting
./2-TroubleshootingControlPlaneBreakStuff-2.sh
```

- Let's start a workload
```
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=4
```

- Interesting, all of the pods are `pending`...
```
kubectl get pods 
```

- Nodes look good? Yes, they're all reporting ready.
```
kubectl get nodes
```

- let's look at the pods' events...<none> nothing, no scheduling, no image pulling, no container starting
```
kubectl describe pods 
```

- What's the next step after the pods are created by the replication controler? Scheduling...
```
kubectl get events --sort-by='.metadata.creationTimestamp'
```

- So we know there's no scheduling events, let's check the control plane status... the scheduler isn't running
```
kubectl get pods --namespace=kube-system
```

- Let's check the events on that pod. We can see if failed fo pull the image for the scheduler, says image not found.
Looks like the manifest is trying to pull an image that doesn't exist.
```
kubectl describe pods --namespace kube-system kube-scheduler-cp1
```

- That's defined in the static pod manifest. Go there and correct the image name
```
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
```

- Is the scheduler back online, yes, it's running 
```
kubectl get pods --namespace=kube-system
```

- And our deployment is now up and running, might take a minute or two for the pods to start up.
```
kubectl get deployment
```

- Clean up our resources...
```
kubectl delete deployments.apps nginx 
```