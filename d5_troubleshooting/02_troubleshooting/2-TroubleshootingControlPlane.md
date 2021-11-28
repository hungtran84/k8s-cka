# Control Plane Pods Stopped

- Remember the master still has a kubelet and runs pods...if the kubelet's not running then troubleshoot that first.
This section focuses on the control plane when it's running the control plane as pods
Let break the control plane

```shell
ssh <user>@<master_node>
sudo mv /etc/kubernetes/manifests/ /etc/kubernetes/manifests.wrong
```

- Let's check the status of our control plane pods...refused?
It can take a a bit to break the control plane wait until it connection to server was refused

```shell
kubectl get pods --namespace kube-system
```

-Let's ask our container runtime, what's up...well there's pods running on this node, but no control plane pods.
That's your clue...no control plane pods running...what starts up the control plane pods...static pod manifests

```shell
sudo docker ps
```

- Let's check config.yaml for the location of the static pod manifests
Look for staticPodPath
Do the yaml files exist at that location?

```shell
sudo more /var/lib/kubelet/config.yaml
```

- The directory doesn't exist...oh no!

```shell
sudo ls -laR /etc/kubernetes/manifests
```

- Let's look up one directory...

```shell
sudo ls -la /etc/kubernetes/
```

- We could update config.yaml to point to this path or rename it to put the manifests in the configured location.
The kubelet will find these manifests and launch the pods again.

```shell
sudo mv /etc/kubernetes/manifests.wrong /etc/kubernetes/manifests
sudo ls /etc/kubernetes/manifests/
```

- Check the container runtime to ensure the pods are started...we can see they were created and running just a few seconds ago

```shell
sudo docker ps 
```

- Let's ask kubernetes whats it thinks...

```shell
kubectl get pods -n kube-system 
```


# Troubleshooting control plane failure, user Pods are all pending.

- Jump into master and Break the control plane

```shell
ssh <user>@<master_node>
sudo cp kube-scheduler.yaml /etc/kubernetes/manifests
sudo chmod 400 /etc/kubernetes/manifests/kube-scheduler.manifest
```

- Let's start a workload

```shell
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=4
```

- Interesting, all of the pods are pending...why?

```shell
kubectl get pods 
```

- Nodes look good? Yes, they're all reporting ready.

```shell
kubectl get nodes
```

- let's look at the pods' events... nothing, no scheduling, no image pulling, no container starting...let's zoom out

```shell
kubectl describe pods 
```

- What's the next step after the pods are created by the replication controler? Scheduling...

```shell
kubectl get events --sort-by='.metadata.creationTimestamp'
```

- So we know there's no scheduling events, let's check the control plane status...the scheduler isn't listening

```shell
kubectl get componentstatuses 
```

- Ah, the scheduler pod is reporting ImagePullBackoff

```shell
kubectl get pods -n kube-system
```

- Let's check the events on that pod...we can see if failed fo pull the image for the scheduler, says image not found.
Looks like the manifest is trying to pull an image that doesn't exist

```shell
kubectl describe pods -b kube-system kube-scheduler-master-asia-southeast1-a-z043 
```

- That's defined in the static pod manifest

```shell
sudo vi /etc/kubernetes/manifests/kube-scheduler.manifest
```

- Is the scheduler back online, yes, it's running

```shell
kubectl get pods --namespace kube-system
```

- it's healthy

```shell
kubectl get componentstatuses 
```

- And our deployment is now up and running...might take a minute or two for the pods to start up.

```shell
kubectl get deployment
```

- Clean up our resources...

```shell
kubectl delete deployments.apps nginx 
```
