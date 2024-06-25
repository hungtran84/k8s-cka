## Pods
- Start up kubectl get events --watch and background it.
```
kubectl get events --watch &
```
- Create a pod. We can see the scheduling, container pulling and container starting.
```
kubectl apply -f pod.yaml

0s          Normal    Scheduled                 pod/hello-world-pod   Successfully assigned default/hello-world-pod to node5
0s          Normal    Pulling                   pod/hello-world-pod   Pulling image "ghcr.io/hungtran84/hello-app:1.0"
0s          Normal    Pulled                    pod/hello-world-pod   Successfully pulled image "ghcr.io/hungtran84/hello-app:1.0" in 3.584474683s (3.584491183s including waiting)
0s          Normal    Created                   pod/hello-world-pod   Created container hello-world
0s          Normal    Started                   pod/hello-world-pod   Started container hello-world
0s          Normal    Starting                  node/node2            Starting kubelet.
...
```

- Start a Deployment with 1 replica. We see the deployment created, scaling the replica set and the replica set starting the first pod
```
kubectl apply -f deployment.yaml

0s          Normal    ScalingReplicaSet         deployment/hello-world   Scaled up replica set hello-world-6d59dfc665 to 1
0s          Normal    SuccessfulCreate          replicaset/hello-world-6d59dfc665   Created pod: hello-world-6d59dfc665-mzhdq
0s          Normal    Scheduled                 pod/hello-world-6d59dfc665-mzhdq    Successfully assigned default/hello-world-6d59dfc665-mzhdq to node2
0s          Normal    Pulling                   pod/hello-world-6d59dfc665-mzhdq    Pulling image "ghcr.io/hungtran84/hello-app:1.0"
0s          Normal    Pulled                    pod/hello-world-6d59dfc665-mzhdq    Successfully pulled image "ghcr.io/hungtran84/hello-app:1.0" in 3.894205399s (3.894220099s including waiting)
0s          Normal    Created                   pod/hello-world-6d59dfc665-mzhdq    Created container hello-world
0s          Normal    Started                   pod/hello-world-6d59dfc665-mzhdq    Started container hello-world
```

- Scale a Deployment to 2 replicas. We see the scaling the replica set and the replica set starting the second pod
```
kubectl scale deployment hello-world --replicas=2

0s          Normal    ScalingReplicaSet         deployment/hello-world              Scaled up replica set hello-world-6d59dfc665 to 2 from 1
0s          Normal    SuccessfulCreate          replicaset/hello-world-6d59dfc665   Created pod: hello-world-6d59dfc665-v9bbz
0s          Normal    Scheduled                 pod/hello-world-6d59dfc665-v9bbz    Successfully assigned default/hello-world-6d59dfc665-v9bbz to node4
0s          Normal    Pulling                   pod/hello-world-6d59dfc665-v9bbz    Pulling image "ghcr.io/hungtran84/hello-app:1.0"
0s          Normal    Starting                  node/node2                          Starting kubelet.
0s          Normal    Pulled                    pod/hello-world-6d59dfc665-v9bbz    Successfully pulled image "ghcr.io/hungtran84/hello-app:1.0" in 3.380702072s (3.380746573s including waiting)
0s          Normal    Created                   pod/hello-world-6d59dfc665-v9bbz    Created container hello-world
0s          Normal    Started                   pod/hello-world-6d59dfc665-v9bbz    Started container hello-world
```

- We start off with the replica set scaling to 1, then  Pod deletion, then the Pod killing the container 
```
kubectl scale deployment hello-world --replicas=1

0s          Normal    ScalingReplicaSet         deployment/hello-world              Scaled down replica set hello-world-6d59dfc665 to 1 from 2
0s          Normal    Killing                   pod/hello-world-6d59dfc665-v9bbz    Stopping container hello-world
0s          Normal    SuccessfulDelete          replicaset/hello-world-6d59dfc665   Deleted pod: hello-world-6d59dfc665-v9bbz
```

- Let's use exec a command inside our container, we can see the GET and POST API requests through the API server to reach the pod.
```
kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-6d59dfc665-mzhdq   1/1     Running   0          3m49s
hello-world-pod                1/1     Running   0          43m

kubectl exec -it hello-world-pod -- /bin/sh

0813 11:24:30.892018   10276 loader.go:373] Config loaded from file:  /root/.kube/config
I0813 11:24:30.913264   10276 round_trippers.go:553] GET https://192.168.0.8:6443/api/v1/namespaces/default/pods/hello-world-pod 200 OK in 11 milliseconds
I0813 11:24:30.918085   10276 podcmd.go:88] Defaulting container name to hello-world
I0813 11:24:30.945208   10276 round_trippers.go:553] POST https://192.168.0.8:6443/api/v1/namespaces/default/pods/hello-world-pod/exec?command=%2Fbin%2Fsh&container=hello-world&stdin=true&stdout=true&tty=true 101 Switching Protocols in 26 milliseconds

/app # ps
PID   USER     TIME  COMMAND
    1 root      0:00 ./hello-app
   11 root      0:00 /bin/sh
   18 root      0:00 ps

/app # exit
```

- Let's look at the running container/pod from the process level on a Node.
```
kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE     IP         NODE    NOMINATED NODE   READINESS GATES
hello-world-6d59dfc665-mzhdq   1/1     Running   0          6m32s   10.5.1.2   node2   <none>           <none>
hello-world-pod                1/1     Running   0          46m     10.5.4.2   node5   <none>           <none>

# run from node2
[node2 ~]$ ps -aux | grep hello-app
root      2183  0.0  0.0   9100   880 pts/1    S+   11:27   0:00 grep --color=auto hello-app
root     30980  0.0  0.0 713552  3908 ?        Ssl  11:20   0:00 ./hello-app

exit
```

- Now, let's access our Pod's application directly, without a service and also off the Pod network.
```
kubectl port-forward hello-world-pod 8080:8080 &
```
- We can point curl to localhost, and kubectl port-forward will send the traffic through the API server to the Pod
```
curl http://localhost:8080
Handling connection for 8080
Hello, world!
Version: 1.0.0
hello-world-pod
```
- Kill our port forward session.
```
fg
ctrl+c
```
- Cleanup resources
```
kubectl delete deployment hello-world
kubectl delete pod hello-world-pod
```
- Kill off the kubectl get events
```
fg
ctrl+c
```

## Static pods
- Quickly create a Pod manifest using `kubectl run` with `dry-run` and `-o yaml`. Copy the manifest to the clipboard for next step
```
kubectl run hello-world --image=ghcr.io/hungtran84/hello-app:2.0 --dry-run=client -o yaml --port=8080 
```
- Log into a node.
Find the staticPodPath:
```
[node2 ~]$ cat /var/lib/kubelet/config.yaml

apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
containerRuntimeEndpoint: ""
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
  verbosity: 0
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
rotateCertificates: true
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
```

- Create a Pod manifest in the `staticPodPath`, paste in the manifest we created above
```
vi /etc/kubernetes/manifests/mypod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: hello-world
  name: hello-world
spec:
  containers:
  - image: ghcr.io/hungtran84/hello-app:2.0
    name: hello-world
    ports:
    - containerPort: 8080
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

- Log out of node and back onto cp/master node.
Get a listing of pods, the pods name is podname + node name
```
kubectl get pods -o wide

NAME                READY   STATUS    RESTARTS   AGE   IP         NODE    NOMINATED NODE   READINESS GATES
hello-world-node2   1/1     Running   0          99s   10.5.1.4   node2   <none>           <none>
```
- Try to delete the pod...
```
kubectl delete pod hello-world-node2
```

- It's still there...
```
kubectl get pods

NAME                READY   STATUS    RESTARTS   AGE
hello-world-node2   1/1     Running   0          23s
```

- Log into `node2` and remove the static pod manifest on the node
```
[node2 ~]$ rm /etc/kubernetes/manifests/mypod.yaml
```
- Switch back to `node1` - the CP one. 
The pod is now gone.
``` 
kubectl get pods
No resources found in default namespace.
```
