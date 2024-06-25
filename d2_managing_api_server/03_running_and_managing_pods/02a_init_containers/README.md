## Init container

- Use a watch to watch the progress.
Each init container run to completion then the app container will start and the Pod status changes to `Running`.
```
kubectl get pods --watch &
```

- Let's have a quick look at the pod manifest with init containers.
```yaml
# init-containers.yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-containers
spec:
  initContainers:
  - name: init-service
    image: ubuntu
    command: ['sh', '-c', "echo waiting for service; sleep 2"]
  - name: init-database
    image: ubuntu
    command: ['sh', '-c', "echo waiting for database; sleep 2"]
  containers:
  - name: app-container
    image: nginx
```
- Create the Pod with 2 init containers.
Each `init container` will be processed serially until completion before the main application container is started
```

kubectl apply -f init-containers.yaml
pod/init-containers created
NAME              READY   STATUS    RESTARTS   AGE
init-containers   0/1     Pending   0          0s
init-containers   0/1     Pending   0          0s
init-containers   0/1     Init:0/2   0          0s
init-containers   0/1     Init:0/2   0          2s
init-containers   0/1     Init:1/2   0          4s
init-containers   0/1     Init:1/2   0          5s
init-containers   0/1     PodInitializing   0          7s
init-containers   1/1     Running           0          8s
```

- Review the `Init-Containers` section and you will see each init container state is `Teminated and Completed` and the main app container is `Running`.
Looking at `Events`, you should see each init container starting serially and then the application container starting last once the others have completed
```
kubectl describe pods init-containers | more 

Name:             init-containers
Namespace:        default
Priority:         0
Service Account:  default
Node:             node4/192.168.0.15
Start Time:       Mon, 14 Aug 2023 05:46:34 +0000
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.5.3.4
IPs:
  IP:  10.5.3.4
Init Containers:
  init-service:
    Container ID:  containerd://8a01ca8f3b213f3e6a1826dac78a978fd69b5101dfd08e14c0006a2b45514968
    Image:         ubuntu
    Image ID:      docker.io/library/ubuntu@sha256:0bced47fffa3361afa981854fcabcd4577cd43cebbb808cea2b1f33a3dd7f508
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo waiting for service; sleep 2
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Mon, 14 Aug 2023 05:46:36 +0000
      Finished:     Mon, 14 Aug 2023 05:46:38 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-pthqr (ro)
  init-database:
    Container ID:  containerd://2eb293c60a358eb162675e41e8040460a91da16b59e372a8ced224d5bcc2d85e
    Image:         ubuntu
    Image ID:      docker.io/library/ubuntu@sha256:0bced47fffa3361afa981854fcabcd4577cd43cebbb808cea2b1f33a3dd7f508
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo waiting for database; sleep 2
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Mon, 14 Aug 2023 05:46:39 +0000
      Finished:     Mon, 14 Aug 2023 05:46:41 +0000
    Ready:          True
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  2m9s  default-scheduler  Successfully assigned default/init-containers to node4
  Normal  Pulling    2m8s  kubelet            Pulling image "ubuntu"
  Normal  Pulled     2m7s  kubelet            Successfully pulled image "ubuntu" in 665.197683ms (665.212483ms including waiting)
  Normal  Created    2m7s  kubelet            Created container init-service
  Normal  Started    2m7s  kubelet            Started container init-service
  Normal  Pulling    2m5s  kubelet            Pulling image "ubuntu"
  Normal  Pulled     2m4s  kubelet            Successfully pulled image "ubuntu" in 689.155165ms (689.174266ms including waiting)
  Normal  Created    2m4s  kubelet            Created container init-database
  Normal  Started    2m4s  kubelet            Started container init-database
  Normal  Pulling    2m2s  kubelet            Pulling image "nginx"
  Normal  Pulled     2m1s  kubelet            Successfully pulled image "nginx" in 680.398601ms (680.439103ms including waiting)
  Normal  Created    2m1s  kubelet            Created container app-container
  Normal  Started    2m1s  kubelet            Started container app-container
```

- Delete the pod
```
kubectl delete -f init-containers.yaml
```

- Kill the watch
```
fg
ctrl+c
```