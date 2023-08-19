## 2.1 - Updating to a non-existent image. 

- Delete any current deployments, because we're interested in the deploy state changes.
```
kubectl delete deployment hello-world
kubectl delete service hello-world
```

- Create our v1 deployment, then update it to v2
```
kubectl apply -f deployment.yaml
deployment.apps/hello-world created
service/hello-world created

kubectl apply -f deployment.v2.yaml
deployment.apps/hello-world configured
service/hello-world unchanged
```

- Observe behavior since new image wasn’t available, the `ReplicaSet` doesn't go below `maxUnavailable`
```
kubectl apply -f deployment.broken.yaml
deployment.apps/hello-world configured
service/hello-world unchanged
```



- Why isn't this finishing after `progressDeadlineSeconds` which we set to 10 seconds (defaults to 10 minutes)?
```
kubectl rollout status deployment hello-world
error: deployment "hello-world" exceeded its progress deadline
```

- Expect a return code of 1 from kubectl rollout status, that's how we know we're in the failed status.
```
echo $?
1
```

- Let's check out `Pods`, `ImagePullBackoff`/`ErrImagePull`. Bingo! An error in our image definition.
Also, it stopped the rollout at 5, that's kind of nice isn't it?
And 8 are online, let's look at why.
```
kubectl get pods

NAME                           READY   STATUS             RESTARTS   AGE
hello-world-664cfdb6fd-khl49   0/1     ImagePullBackOff   0          2m39s
hello-world-664cfdb6fd-nppmp   0/1     ImagePullBackOff   0          2m39s
hello-world-664cfdb6fd-rkj9d   0/1     ImagePullBackOff   0          2m39s
hello-world-664cfdb6fd-sddmv   0/1     ImagePullBackOff   0          2m39s
hello-world-664cfdb6fd-zgvxt   0/1     ImagePullBackOff   0          2m39s
hello-world-66d45dfbcd-2nb58   1/1     Running            0          4m49s
hello-world-66d45dfbcd-5hgfw   1/1     Running            0          4m51s
hello-world-66d45dfbcd-5n4jn   1/1     Running            0          4m51s
hello-world-66d45dfbcd-8nrxk   1/1     Running            0          4m51s
hello-world-66d45dfbcd-8zlvv   1/1     Running            0          4m51s
hello-world-66d45dfbcd-h55nr   1/1     Running            0          4m50s
hello-world-66d45dfbcd-p585l   1/1     Running            0          4m50s
hello-world-66d45dfbcd-pl54d   1/1     Running            0          4m51s
```

- What is `maxUnavailable`? 25% (2.5 roundown to 2). So only two Pods in the ORIGINAL `ReplicaSet` are offline and 8 are online.
What is maxSurge? 25% (2.5 roundup to 3). So we have 13 total Pods, or 25% in addition to Desired number.
Look at `Replicas` and `OldReplicaSet` 8/8 and `NewReplicaSet` 5/5.
```
    Available      True    MinimumReplicasAvailable
    Progressing    False   ProgressDeadlineExceeded
```

```
kubectl describe deployments hello-world 

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Wed, 16 Aug 2023 23:25:23 +0700
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 3
Selector:               app=hello-world
Replicas:               10 desired | 5 updated | 13 total | 8 available | 5 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=hello-world
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-ap:2.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    False   ProgressDeadlineExceeded
OldReplicaSets:  hello-world-66d45dfbcd (8/8 replicas created)
NewReplicaSet:   hello-world-664cfdb6fd (5/5 replicas created)
Events:
  Type    Reason             Age                 From                   Message
  ----    ------             ----                ----                   -------
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled up replica set hello-world-6d59dfc665 to 10
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 3
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 8 from 10
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 5 from 3
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 7 from 8
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 6 from 5
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 6 from 7
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 7 from 6
  Normal  ScalingReplicaSet  26m                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 5 from 6
  Normal  ScalingReplicaSet  24m (x11 over 26m)  deployment-controller  (combined from similar events): Scaled up replica set hello-world-664cfdb6fd to 5 from 3
```
- Let's sort this out now. 
Check the rollout history, but which revision should we rollback to?
```
kubectl rollout history deployment hello-world
deployment.apps/hello-world 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
```

- It's easy in this example, but could be harder for complex systems.
Let's look at our revision Annotation, should be 3
```
kubectl describe deployments hello-world | head

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Wed, 16 Aug 2023 23:25:23 +0700
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 3
Selector:               app=hello-world
Replicas:               10 desired | 5 updated | 13 total | 8 available | 5 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
```

- We can also look at the changes applied in each revision to see the new pod templates.
```
kubectl rollout history deployment hello-world --revision=2
deployment.apps/hello-world with revision #2
Pod Template:
  Labels:       app=hello-world
        pod-template-hash=66d45dfbcd
  Containers:
   hello-world:
    Image:      ghcr.io/hungtran84/hello-app:2.0
    Port:       8080/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>

kubectl rollout history deployment hello-world --revision=3
deployment.apps/hello-world with revision #3
Pod Template:
  Labels:       app=hello-world
        pod-template-hash=664cfdb6fd
  Containers:
   hello-world:
    Image:      ghcr.io/hungtran84/hello-ap:2.0
    Port:       8080/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

- Let's undo our rollout to revision 2, which is our v2 container.
```
kubectl rollout undo deployment hello-world --to-revision=2
deployment.apps/hello-world rolled back

kubectl rollout status deployment hello-world
deployment "hello-world" successfully rolled out

echo $?
0
```

- We're back to Desired of 10 and 2 new Pods where deployed using the previous Deployment Replicas/Container Image.
```
kubectl get pods

NAME                           READY   STATUS    RESTARTS   AGE
hello-world-66d45dfbcd-2nb58   1/1     Running   0          33m
hello-world-66d45dfbcd-5d4b6   1/1     Running   0          48s
hello-world-66d45dfbcd-5hgfw   1/1     Running   0          33m
hello-world-66d45dfbcd-5n4jn   1/1     Running   0          33m
hello-world-66d45dfbcd-8nrxk   1/1     Running   0          33m
hello-world-66d45dfbcd-8zlvv   1/1     Running   0          33m
hello-world-66d45dfbcd-h55nr   1/1     Running   0          33m
hello-world-66d45dfbcd-p585l   1/1     Running   0          33m
hello-world-66d45dfbcd-pl54d   1/1     Running   0          33m
hello-world-66d45dfbcd-wpd8f   1/1     Running   0          48s
```

- Let's delete this Deployment and start over with a new Deployment.
```
kubectl delete deployment hello-world
kubectl delete service hello-world
```


## Controlling the rate and update strategy of a Deployment update.
- Let's deploy a `Deployment` with `Readiness` Probes
```
kubectl apply -f deployment.probes-1.yaml --record

Flag --record has been deprecated, --record will be removed in the future
deployment.apps/hello-world created
service/hello-world created
```

- Check  `Replicas` and `Conditions`, all Pods should be online and ready.

```
kubectl describe deployment hello-world

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Thu, 17 Aug 2023 00:09:09 +0700
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
                        kubernetes.io/change-cause: kubectl apply --filename=deployment.probes-1.yaml --record=true
Selector:               app=hello-world
Replicas:               20 desired | 20 updated | 20 total | 20 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  10% max unavailable, 2 max surge
Pod Template:
  Labels:  app=hello-world
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:1.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Readiness:    http-get http://:8080/index.html delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   hello-world-55574f5d66 (20/20 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  47s   deployment-controller  Scaled up replica set hello-world-55574f5d66 to 20
```

- Let's update from v1 to v2 with Readiness Probes Controlling the rollout, and record our rollout
```
diff deployment.probes-1.yaml deployment.probes-2.yaml
23c23
<         image: ghcr.io/hungtran84/hello-app:1.0
---
> 

kubectl apply -f deployment.probes-2.yaml --record
deployment.apps/hello-world configured
service/hello-world configured
```

- Lots of pods, most are not ready yet, but progressing. Wow do we know it's progressing?
kubectl get replicaset
NAME                     DESIRED   CURRENT   READY   AGE
hello-world-55574f5d66   14        14        14      6m44s
hello-world-57db99fb49   8         8         4       28s

- Check again, Replicas and Conditions. 
Progressing is now ReplicaSetUpdated, will change to NewReplicaSetAvailable when it's Ready
#NewReplicaSet is THIS current RS, OldReplicaSet is populated during a Rollout, otherwise it's <None>
#We used the update strategy settings of max unavailable and max surge to slow this rollout down.
#This update takes about a minute to rollout
```
kubectl describe deployment hello-world
...
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    ReplicaSetUpdated
...
...
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
...
```


- Let's update again without checking the `diff`, we're going to troubleshoot it later.
```
kubectl apply -f deployment.probes-3.yaml --record

Flag --record has been deprecated, --record will be removed in the future
deployment.apps/hello-world configured
service/hello-world configured
```

- We stall at 4 out of 20 replicas updated...let's look
```
kubectl rollout status deployment hello-world
Waiting for deployment "hello-world" rollout to finish: 4 out of 20 new replicas have been updated...
```

- Let's check the status of the `Deployment`, `Replicas` and `Conditions`.
    - 22 total (20 original + 2 max surge) \
    - 18 available (20 original - 2 (10%) in the old RS) \
    - 4 Unavailable, (only 2 pods in the old RS are offline, 4 in the new RS are not READY)

```
kubectl describe deployment hello-world

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Thu, 17 Aug 2023 00:09:09 +0700
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 3
                        kubernetes.io/change-cause: kubectl apply --filename=deployment.probes-3.yaml --record=true
Selector:               app=hello-world
Replicas:               20 desired | 4 updated | 22 total | 18 available | 4 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  10% max unavailable, 2 max surge
Pod Template:
  Labels:  app=hello-world
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:2.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Readiness:    http-get http://:8081/index.html delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    ReplicaSetUpdated
```

- Let's look at our `ReplicaSets`, no Pods in the new RS `hello-world-5c5cf688f8` are READY, but 4 our deployed.
That RS with Desired `0` is from our `V1` deployment, `18` is from our `V2` deployment.
```
kubectl get replicaset

NAME                     DESIRED   CURRENT   READY   AGE
hello-world-55574f5d66   0         0         0       16m
hello-world-57db99fb49   18        18        18      9m46s
hello-world-5c5cf688f8   4         4         0       4m12s
```

- let's check the deployment again.
What keeps a pod from reporting ready? A Readiness Probe. See that Readiness Probe. tada! Wrong port found!
```
kubectl describe deployment hello-world

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Thu, 17 Aug 2023 00:09:09 +0700
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 3
                        kubernetes.io/change-cause: kubectl apply --filename=deployment.probes-3.yaml --record=true
Selector:               app=hello-world
Replicas:               20 desired | 4 updated | 22 total | 18 available | 4 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  10% max unavailable, 2 max surge
Pod Template:
  Labels:  app=hello-world
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:2.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Readiness:    http-get http://:8081/index.html delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
```

- We can read the `Deployment`'s rollout history, and see our `CHANGE-CAUSE` annotations
```
kubectl rollout history deployment hello-world
deployment.apps/hello-world 
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=deployment.probes-1.yaml --record=true
2         kubectl apply --filename=deployment.probes-2.yaml --record=true
3         kubectl apply --filename=deployment.probes-3.yaml --record=true
```

- Let's rollback to revision 2 to undo that change...
```
kubectl rollout history deployment hello-world --revision=3
deployment.apps/hello-world with revision #3
Pod Template:
  Labels:       app=hello-world
        pod-template-hash=5c5cf688f8
  Annotations:  kubernetes.io/change-cause: kubectl apply --filename=deployment.probes-3.yaml --record=true
  Containers:
   hello-world:
    Image:      ghcr.io/hungtran84/hello-app:2.0
    Port:       8080/TCP
    Host Port:  0/TCP
    Readiness:  http-get http://:8081/index.html delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```
```
kubectl rollout history deployment hello-world --revision=2
Pod Template:
  Labels:       app=hello-world
        pod-template-hash=57db99fb49
  Annotations:  kubernetes.io/change-cause: kubectl apply --filename=deployment.probes-2.yaml --record=true
  Containers:
   hello-world:
    Image:      ghcr.io/hungtran84/hello-app:2.0
    Port:       8080/TCP
    Host Port:  0/TCP
    Readiness:  http-get http://:8080/index.html delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```
```
kubectl rollout undo deployment hello-world --to-revision=2
deployment.apps/hello-world rolled back
```

- And check out our deployment to see if we get 20 Ready replicas
```
kubectl describe deployment | head
Name:                   hello-world
Namespace:              default
CreationTimestamp:      Thu, 17 Aug 2023 00:09:09 +0700
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 4
                        kubernetes.io/change-cause: kubectl apply --filename=deployment.probes-2.yaml --record=true
Selector:               app=hello-world
Replicas:               20 desired | 20 updated | 20 total | 20 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
```
```
kubectl get deployment
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
hello-world   20/20   20           20          26m
```

- Let's clean up
```
kubectl delete deployment hello-world
kubectl delete service hello-world
```

- Restarting a deployment. Create a fresh deployment so we have easier to read logs.
```
kubectl create deployment hello-world --image=ghcr.io/hungtran84/hello-app:1.0 --replicas=5
deployment.apps/hello-world created
```

- Check the status of the deployment
```
kubectl get deployment
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
hello-world   5/5     5            5           22s
```

- Check the status of the pods and take note of the pod template hash in the NAME and the AGE
```
kubectl get pods 
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-5bc74c8b8d-5s9b2   1/1     Running   0          59s
hello-world-5bc74c8b8d-j5vwc   1/1     Running   0          59s
hello-world-5bc74c8b8d-w8vp5   1/1     Running   0          59s
hello-world-5bc74c8b8d-wpdfn   1/1     Running   0          59s
hello-world-5bc74c8b8d-xr99m   1/1     Running   0          59s
```

- Let's restart a deployment
```
kubectl rollout restart deployment hello-world 
deployment.apps/hello-world restarted
```

- You get a new `replicaset` and the pods in the old replicaset are shutdown and the new replicaset are started up
```
kubectl describe deployment hello-world
...
OldReplicaSets:  <none>
NewReplicaSet:   hello-world-b6b9589d (5/5 replicas created)
...
```

- All new pods in the replicaset 
```
kubectl get pods 
NAME                         READY   STATUS    RESTARTS   AGE
hello-world-b6b9589d-665bx   1/1     Running   0          68s
hello-world-b6b9589d-78h28   1/1     Running   0          69s
hello-world-b6b9589d-795q6   1/1     Running   0          69s
hello-world-b6b9589d-ck2ws   1/1     Running   0          68s
hello-world-b6b9589d-ws9jt   1/1     Running   0          69s
```

- Cleanup time
```
kubectl delete deployment hello-world
```