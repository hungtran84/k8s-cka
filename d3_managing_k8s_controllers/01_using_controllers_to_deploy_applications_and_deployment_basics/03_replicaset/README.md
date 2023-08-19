## Deploy a Deployment which creates a ReplicaSet
```
kubectl apply -f deployment.yaml
deployment.apps/hello-world created
service/hello-world created

kubectl get replicaset
NAME                     DESIRED   CURRENT   READY   AGE
hello-world-5c7b5b8dfd   5         5         5       2s
```


- Let's look at the selector for this one and the labels in the pod template
```
kubectl describe replicaset hello-world

Name:           hello-world-5c7b5b8dfd
Namespace:      default
Selector:       app=hello-world,pod-template-hash=5c7b5b8dfd
Labels:         app=hello-world
                pod-template-hash=5c7b5b8dfd
Annotations:    deployment.kubernetes.io/desired-replicas: 5
                deployment.kubernetes.io/max-replicas: 7
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/hello-world
Replicas:       5 current / 5 desired
Pods Status:    5 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world
           pod-template-hash=5c7b5b8dfd
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:1.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age   From                   Message
  ----    ------            ----  ----                   -------
  Normal  SuccessfulCreate  56s   replicaset-controller  Created pod: hello-world-5c7b5b8dfd-ncspp
  Normal  SuccessfulCreate  56s   replicaset-controller  Created pod: hello-world-5c7b5b8dfd-rlmng
  Normal  SuccessfulCreate  56s   replicaset-controller  Created pod: hello-world-5c7b5b8dfd-5g5ns
  Normal  SuccessfulCreate  56s   replicaset-controller  Created pod: hello-world-5c7b5b8dfd-tkl96
  Normal  SuccessfulCreate  56s   replicaset-controller  Created pod: hello-world-5c7b5b8dfd-x95rg
```

- Let's delete this deployment which will delete the replicaset
```
kubectl delete deployment hello-world
deployment.apps "hello-world" deleted

kubectl get replicaset
No resources found in default namespace.
```

- Deploy a `ReplicaSet` with `matchExpressions`
```yaml
# more deployment-me.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 5
  selector:
    matchExpressions:
      - key: app
        operator: In
        values:
          - hello-world-pod-me
  template:
    metadata:
      labels:
        app: hello-world-pod-me
    spec:
      containers:
      - name: hello-world
        image: ghcr.io/hungtran84/hello-app:1.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world-pod
spec:
  selector:
    app: hello-world-pod-me
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
```

```
kubectl apply -f deployment-me.yaml
deployment.apps/hello-world created
service/hello-world-pod created
```

- Check on the status of our ReplicaSet
```
kubectl get replicaset


#Let's look at the Selector for this one...and the labels in the pod template
kubectl describe replicaset hello-world

NAME                    DESIRED   CURRENT   READY   AGE
hello-world-64d47845c   5         5         5       29s
```

## Deleting a Pod in a ReplicaSet, application will self-heal itself
```
kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
hello-world-64d47845c-5bgvp   1/1     Running   0          66s
hello-world-64d47845c-cqch6   1/1     Running   0          66s
hello-world-64d47845c-fcmpp   1/1     Running   0          66s
hello-world-64d47845c-k5q5w   1/1     Running   0          66s
hello-world-64d47845c-nr9sg   1/1     Running   0          66s

kubectl delete pods hello-world-64d47845c-5bgvp
pod "hello-world-64d47845c-5bgvp" deleted

kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
hello-world-64d47845c-cqch6   1/1     Running   0          109s
hello-world-64d47845c-fcmpp   1/1     Running   0          109s
hello-world-64d47845c-k5q5w   1/1     Running   0          109s
hello-world-64d47845c-nr9sg   1/1     Running   0          109s
hello-world-64d47845c-tjlxj   1/1     Running   0          14s
```


## Isolating a Pod from a ReplicaSet

```
kubectl get pods --show-labels

NAME                          READY   STATUS    RESTARTS   AGE     LABELS
hello-world-64d47845c-cqch6   1/1     Running   0          2m46s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-fcmpp   1/1     Running   0          2m46s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-k5q5w   1/1     Running   0          2m46s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-nr9sg   1/1     Running   0          2m46s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-tjlxj   1/1     Running   0          71s     app=hello-world-pod-me,pod-template-hash=64d47845c
```

- Edit the label on one of the Pods in the ReplicaSet, the replicaset controller will create a new pod
```
kubectl label pod hello-world-64d47845c-cqch6 app=DEBUG --overwrite
pod/hello-world-64d47845c-cqch6 labeled

kubectl get pods --show-labels
NAME                          READY   STATUS    RESTARTS   AGE     LABELS
hello-world-64d47845c-95bgr   1/1     Running   0          16s     app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-cqch6   1/1     Running   0          4m5s    app=DEBUG,pod-template-hash=64d47845c
hello-world-64d47845c-fcmpp   1/1     Running   0          4m5s    app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-k5q5w   1/1     Running   0          4m5s    app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-nr9sg   1/1     Running   0          4m5s    app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-tjlxj   1/1     Running   0          2m30s   app=hello-world-pod-me,pod-template-hash=64d47845c
```

## Taking over an existing Pod in a `ReplicaSet`
Relabel that pod to bring it back into the scope of the `replicaset`, what's kubernetes going to do?

```
kubectl label pod hello-world-64d47845c-cqch6 app=hello-world-pod-me --overwrite
pod/hello-world-64d47845c-cqch6 labeled
```

- One Pod will be terminated, since it will maintain the desired number of replicas at 5
```
kubectl get pods --show-labels
NAME                          READY   STATUS    RESTARTS   AGE     LABELS
hello-world-64d47845c-cqch6   1/1     Running   0          6m58s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-fcmpp   1/1     Running   0          6m58s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-k5q5w   1/1     Running   0          6m58s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-nr9sg   1/1     Running   0          6m58s   app=hello-world-pod-me,pod-template-hash=64d47845c
hello-world-64d47845c-tjlxj   1/1     Running   0          5m23s   app=hello-world-pod-me,pod-template-hash=64d47845c

kubectl describe ReplicaSets

Name:           hello-world-64d47845c
Namespace:      default
Selector:       app in (hello-world-pod-me),pod-template-hash=64d47845c
Labels:         app=hello-world-pod-me
                pod-template-hash=64d47845c
Annotations:    deployment.kubernetes.io/desired-replicas: 5
                deployment.kubernetes.io/max-replicas: 7
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/hello-world
Replicas:       5 current / 5 desired
Pods Status:    5 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world-pod-me
           pod-template-hash=64d47845c
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:1.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age    From                   Message
  ----    ------            ----   ----                   -------
  Normal  SuccessfulCreate  7m17s  replicaset-controller  Created pod: hello-world-64d47845c-nr9sg
  Normal  SuccessfulCreate  7m17s  replicaset-controller  Created pod: hello-world-64d47845c-fcmpp
  Normal  SuccessfulCreate  7m17s  replicaset-controller  Created pod: hello-world-64d47845c-k5q5w
  Normal  SuccessfulCreate  7m17s  replicaset-controller  Created pod: hello-world-64d47845c-cqch6
  Normal  SuccessfulCreate  7m17s  replicaset-controller  Created pod: hello-world-64d47845c-5bgvp
  Normal  SuccessfulCreate  5m42s  replicaset-controller  Created pod: hello-world-64d47845c-tjlxj
  Normal  SuccessfulCreate  3m28s  replicaset-controller  Created pod: hello-world-64d47845c-95bgr
  Normal  SuccessfulDelete  52s    replicaset-controller  Deleted pod: hello-world-64d47845c-95bgr
```

## Node failures in ReplicaSets
- Shutdow/remove a node
```
sudo shutdown -h now
```

- Node goes `NotReady` after about 1 minute.
```
kubectl get nodes
NAME    STATUS     ROLES           AGE    VERSION
node1   Ready      control-plane   121m   v1.27.2
node2   Ready      <none>          120m   v1.27.2
node3   Ready      <none>          120m   v1.27.2
node4   Ready      <none>          120m   v1.27.2
node5   NotReady   <none>          120m   v1.27.2
```

- But there's a Pod still on the removed node? 
Kubernetes is protecting against transient issues. Assumes the Pod is still running.
```
kubectl get pods -o wide
NAME                          READY   STATUS    RESTARTS   AGE   IP          NODE    NOMINATED NODE   READINESS GATES
hello-world-64d47845c-cqch6   1/1     Running   0          13m   10.5.2.8    node3   <none>           <none>
hello-world-64d47845c-fcmpp   1/1     Running   0          13m   10.5.4.9    node5   <none>           <none>
hello-world-64d47845c-k5q5w   1/1     Running   0          13m   10.5.1.8    node2   <none>           <none>
hello-world-64d47845c-nr9sg   1/1     Running   0          13m   10.5.2.7    node3   <none>           <none>
hello-world-64d47845c-tjlxj   1/1     Running   0          11m   10.5.3.11   node4   <none>           <none>
```

- Start up node5, break out of watch when Node reports Ready, takes about 15 seconds
kubectl get nodes --watch

- It will start the container back up on the Node `node5`.
The pod didn't get rescheduled, it's still there, the container restart policy restarts the container which starts at 10 seconds and defaults to Always. 
```
kubectl get pods -o wide
```

- Let's shutdown/remove node5 again
```
sudo shutdown -h now
```

- Set a watch and wait about 5 minutes and see what kubernetes will do.
Because of the `--pod-eviction-timeout` duration setting on the `kube-controller-manager`, this pod will get killed after `5` minutes.

```
kubectl get pods -owide --watch

NAME                          READY   STATUS    RESTARTS   AGE   IP         NODE    NOMINATED NODE   READINESS GATES
hello-world-64d47845c-5vcqp   1/1     Running   0          10m   10.5.1.7   node3   <none>           <none>
hello-world-64d47845c-9449q   1/1     Running   0          10m   10.5.4.3   node5   <none>           <none>
hello-world-64d47845c-hnn7j   1/1     Running   0          10m   10.5.2.5   node2   <none>           <none>
hello-world-64d47845c-nwrkz   1/1     Running   0          10m   10.5.2.4   node2   <none>           <none>
hello-world-64d47845c-wrjbc   1/1     Running   0          10m   10.5.3.3   node4   <none>           <none>
hello-world-64d47845c-9449q   1/1     Running   0          10m   10.5.4.3   node5   <none>           <none>

hello-world-64d47845c-9449q   1/1     Running   0          15m   10.5.4.3   node5   <none>           <none>
hello-world-64d47845c-9449q   1/1     Terminating   0          15m   10.5.4.3   node5   <none>           <none>
hello-world-64d47845c-7zgrw   0/1     Pending       0          0s    <none>     <none>   <none>           <none>
hello-world-64d47845c-7zgrw   0/1     Pending       0          0s    <none>     node4    <none>           <none>
hello-world-64d47845c-7zgrw   0/1     ContainerCreating   0          0s    <none>     node4    <none>           <none>
hello-world-64d47845c-7zgrw   1/1     Running             0          1s    10.5.3.4   node4    <none>           <none>
```

- Orphaned Pod goes `Terminating` and a new Pod will be deployed in the cluster.
If the Node returns the Pod will be deleted, if the Node does not, we'll have to delete it

```
kubectl get pods -o wide

NAME                          READY   STATUS        RESTARTS   AGE   IP         NODE    NOMINATED NODE   READINESS GATES
hello-world-64d47845c-5vcqp   1/1     Running       0          16m   10.5.1.7   node3   <none>           <none>
hello-world-64d47845c-7zgrw   1/1     Running       0          78s   10.5.3.4   node4   <none>           <none>
hello-world-64d47845c-9449q   1/1     Terminating   0          17m   10.5.4.3   node5   <none>           <none>
hello-world-64d47845c-hnn7j   1/1     Running       0          17m   10.5.2.5   node2   <none>           <none>
hello-world-64d47845c-nwrkz   1/1     Running       0          17m   10.5.2.4   node2   <none>           <none>
hello-world-64d47845c-wrjbc   1/1     Running       0          17m   10.5.3.3   node4   <none>           <none>
```

- Cleanup time
```
kubectl delete deployment hello-world
kubectl delete service hello-world
```
