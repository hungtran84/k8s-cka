## Pod Lifecycle

- Start up kubectl get events --watch and background it.
```
kubectl get events --watch &
clear
```

- Create a pod, we can see the scheduling, container pulling and container starting.
```
kubectl apply -f pod.yaml
```

- We've used exec to launch a shell before, but we can use it to launch ANY program inside a container.
We still have our kubectl get events running in the background, so we see if re-create the container automatically.
Let's use `killall` to kill the `hello-app` process inside our container

```
kubectl exec -it hello-world-pod -- /usr/bin/killall hello-app

0s          Normal   Pulled      pod/hello-world-pod                Container image "ghcr.io/hungtran84/hello-app:1.0" already present on machine
hello-world-pod   0/1     Error               0          14s
0s          Normal   Created     pod/hello-world-pod                Created container hello-world
0s          Normal   Started     pod/hello-world-pod                Started container hello-world
hello-world-pod   1/1     Running             1 (1s ago)   15s
```

- Our `restart count` increased by 1 after the container needed to be restarted.
```
kubectl get pods
NAME              READY   STATUS    RESTARTS       AGE
hello-world-pod   1/1     Running   1 (3m3s ago)   3m17s
```

- Look at Containers->`State`, `Last State`, `Reason`, `Exit Code`, `Restart Count` and `Events`.
This is because the container restart policy is `Always` by default
```
kubectl describe pod hello-world-pod

Name:             hello-world-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             node4/192.168.0.15
Start Time:       Mon, 14 Aug 2023 05:55:07 +0000
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.5.3.5
IPs:
  IP:  10.5.3.5
Containers:
  hello-world:
    Container ID:   containerd://4aedc6dec6ac5c0306e88b01feaa0eece4df5993cc5786474147ede014a0990c
    Image:          ghcr.io/hungtran84/hello-app:1.0
    Image ID:       ghcr.io/hungtran84/hello-app@sha256:a3af38fd5a7dbfe9328f71b00d04516e8e9c778b4886e8aaac8d9e8862a09bc7
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 14 Aug 2023 05:55:21 +0000
    Last State:     Terminated
      Reason:       Error
      Exit Code:    2
      Started:      Mon, 14 Aug 2023 05:55:08 +0000
      Finished:     Mon, 14 Aug 2023 05:55:21 +0000
    Ready:          True
    Restart Count:  1
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2c42n (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-2c42n:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age                   From               Message
  ----    ------     ----                  ----               -------
  Normal  Scheduled  4m15s                 default-scheduler  Successfully assigned default/hello-world-pod to node4
  Normal  Pulled     4m1s (x2 over 4m14s)  kubelet            Container image "ghcr.io/hungtran84/hello-app:1.0" already present on machine
  Normal  Created    4m1s (x2 over 4m14s)  kubelet            Created container hello-world
  Normal  Started    4m1s (x2 over 4m14s)  kubelet            Started container hello-world
```

- Cleanup time
```
kubectl delete pod hello-world-pod
```

- Kill our watch
```
fg
ctrl+c
```

- Remember, we can ask the API server what it knows about an object, in this case our `restartPolicy`
```
kubectl explain pods.spec.restartPolicy

KIND:       Pod
VERSION:    v1

FIELD: restartPolicy <string>

DESCRIPTION:
    Restart policy for all containers within the pod. One of Always, OnFailure,
    Never. In some contexts, only a subset of those values may be permitted.
    Default to Always. More info:
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy
    
    Possible enum values:
     - `"Always"`
     - `"Never"`
     - `"OnFailure"`
```

- Create our pods with the restart policy

```yaml
# more pod-restart-policy.yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-world-onfailure-pod
spec:
  containers:
  - name: hello-world
    image: ghcr.io/hungtran84/hello-app:1.0
  restartPolicy: OnFailure
---
apiVersion: v1
kind: Pod
metadata:
  name: hello-world-never-pod
spec:
  containers:
  - name: hello-world
    image: ghcr.io/hungtran84/hello-app:1.0
  restartPolicy: Never
```

```
kubectl apply -f pod-restart-policy.yaml
```
- Check to ensure both pods are up and running, we can see the restarts is 0
```
kubectl get pods 
NAME                        READY   STATUS    RESTARTS   AGE
hello-world-never-pod       1/1     Running   0          29s
hello-world-onfailure-pod   1/1     Running   0          29s
```

- Let's kill our apps in `hello-world-never-pod` and see how the container restart policy reacts
```
kubectl exec -it hello-world-never-pod -- /usr/bin/killall hello-app

kubectl get pod hello-world-never-pod 
NAME                        READY   STATUS    RESTARTS   AGE
hello-world-never-pod       0/1     Error     0          110s
```

- Review container `state`, `reason`, `exit code`, `Ready` and `ContainerReady`
```
kubectl describe pod hello-world-never-pod

Name:             hello-world-never-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             node4/192.168.0.15
Start Time:       Mon, 14 Aug 2023 06:03:48 +0000
Labels:           <none>
Annotations:      <none>
Status:           Failed
IP:               10.5.3.6
IPs:
  IP:  10.5.3.6
Containers:
  hello-world:
    Container ID:   containerd://257fc1bfe881115ce9e6d7d61c44b0f6607fd8ae99669cd9d1a6d47fb0dd93d4
    Image:          ghcr.io/hungtran84/hello-app:1.0
    Image ID:       ghcr.io/hungtran84/hello-app@sha256:a3af38fd5a7dbfe9328f71b00d04516e8e9c778b4886e8aaac8d9e8862a09bc7
    Port:           <none>
    Host Port:      <none>
    State:          Terminated
      Reason:       Error
      Exit Code:    2
      Started:      Mon, 14 Aug 2023 06:03:49 +0000
      Finished:     Mon, 14 Aug 2023 06:05:28 +0000
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-6h2lb (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  kube-api-access-6h2lb:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  3m9s  default-scheduler  Successfully assigned default/hello-world-never-pod to node4
  Normal  Pulled     3m9s  kubelet            Container image "ghcr.io/hungtran84/hello-app:1.0" already present on machine
  Normal  Created    3m9s  kubelet            Created container hello-world
  Normal  Started    3m8s  kubelet            Started container hello-world
```

- Let's kill our apps in `hello-world-onfailure-pod` and see how the container restart policy reacts 
```
kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app
```

- We'll see 1 restart on the pod with the OnFailure restart policy.
```
kubectl get pods hello-world-onfailure-pod
NAME                        READY   STATUS    RESTARTS      AGE
hello-world-onfailure-pod   1/1     Running   1 (40s ago)   7m50s
```

- Let's kill our app again, with the same signal.
```
kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app
```
- Check its status, which is now Error too...why? The backoff.
```
kubectl get pods hello-world-onfailure-pod
NAME                        READY   STATUS   RESTARTS      AGE
hello-world-onfailure-pod   0/1     Error    2 (58s ago)   9m19s
```

- Let's check the events, we hit the backoff loop. 10 second wait. Then it will restart.
Also check out State and Last State.
```
kubectl describe pod hello-world-onfailure-pod 
...
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  10m                 default-scheduler  Successfully assigned default/hello-world-onfailure-pod to node2
  Warning  BackOff    37s (x3 over 103s)  kubelet            Back-off restarting failed container hello-world in pod hello-world-onfailure-pod_default(89372cdc-a545-492b-9363-6842f410e021)
  Normal   Pulled     24s (x4 over 10m)   kubelet            Container image "ghcr.io/hungtran84/hello-app:1.0" already present on machine
  Normal   Created    24s (x4 over 10m)   kubelet            Created container hello-world
  Normal   Started    24s (x4 over 10m)   kubelet            Started container hello-world
```

- Check its status, should be Running...after the Backoff timer expires.
```
kubectl get pods 
NAME                        READY   STATUS    RESTARTS       AGE
hello-world-onfailure-pod   1/1     Running   3 (111s ago)   11m
```

- Cleanup time
```
kubectl delete pod hello-world-never-pod
kubectl delete pod hello-world-onfailure-pod
```