## Updating a Deployment and checking our rollout status

- Let's start off with rolling out v1
```
kubectl apply -f deployment.yaml

deployment.apps/hello-world created
service/hello-world created
```

- Check the status of the deployment
```
kubectl get deployment hello-world
AME          READY   UP-TO-DATE   AVAILABLE   AGE
hello-world   10/10   10           10          40s
```

- Now let's apply that deployment and the next command at the same time
```
kubectl apply -f deployment.v2.yaml

deployment.apps/hello-world configured
```

- Let's check the status of that rollout, while the command blocking your deployment is in the Progressing status.
```
kubectl rollout status deployment hello-world

Waiting for deployment "hello-world" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 7 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 7 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "hello-world" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "hello-world" rollout to finish: 9 of 10 updated replicas are available...
deployment "hello-world" successfully rolled out
```

- Expect a return code of 0 from kubectl rollout status, that's how we know we're in the Complete status.
```
echo $?
0
```

- Let's walk through the description of the deployment.
Check out `Replicas`, `Conditions` and `Events`, `OldReplicaSet` (will only be populated during a rollout) and `NewReplicaSet`

```
kubectl describe deployments hello-world

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Wed, 16 Aug 2023 22:53:38 +0700
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 2
Selector:               app=hello-world
Replicas:               10 desired | 10 updated | 10 total | 10 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=hello-world
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:2.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   hello-world-66d45dfbcd (10/10 replicas created)
Events:
  Type    Reason             Age                  From                   Message
  ----    ------             ----                 ----                   -------
  Normal  ScalingReplicaSet  6m42s                deployment-controller  Scaled up replica set hello-world-6d59dfc665 to 10
  Normal  ScalingReplicaSet  2m9s                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 3
  Normal  ScalingReplicaSet  2m9s                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 8 from 10
  Normal  ScalingReplicaSet  2m9s                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 5 from 3
  Normal  ScalingReplicaSet  119s                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 7 from 8
  Normal  ScalingReplicaSet  119s                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 6 from 5
  Normal  ScalingReplicaSet  119s                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 6 from 7
  Normal  ScalingReplicaSet  119s                 deployment-controller  Scaled up replica set hello-world-66d45dfbcd to 7 from 6
  Normal  ScalingReplicaSet  119s                 deployment-controller  Scaled down replica set hello-world-6d59dfc665 to 5 from 6
  Normal  ScalingReplicaSet  117s (x8 over 119s)  deployment-controller  (combined from similar events): Scaled down replica set hello-world-6d59dfc665 to 0 from 1
```

- Both replicasets remain, and that will become very useful shortly when we use a rollback
```
kubectl get replicaset

NAME                     DESIRED   CURRENT   READY   AGE
hello-world-66d45dfbcd   10        10        10      5m19s
hello-world-6d59dfc665   0         0         0       9m52s
```

- The `NewReplicaSet`, check out labels, replicas, status and pod-template-hash
```
kubectl describe replicaset hello-world-66d45dfbcd

Name:           hello-world-66d45dfbcd
Namespace:      default
Selector:       app=hello-world,pod-template-hash=66d45dfbcd
Labels:         app=hello-world
                pod-template-hash=66d45dfbcd
Annotations:    deployment.kubernetes.io/desired-replicas: 10
                deployment.kubernetes.io/max-replicas: 13
                deployment.kubernetes.io/revision: 2
Controlled By:  Deployment/hello-world
Replicas:       10 current / 10 desired
Pods Status:    10 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world
           pod-template-hash=66d45dfbcd
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:2.0
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age    From                   Message
  ----    ------            ----   ----                   -------
  Normal  SuccessfulCreate  6m14s  replicaset-controller  Created pod: hello-world-66d45dfbcd-d2m88
  Normal  SuccessfulCreate  6m14s  replicaset-controller  Created pod: hello-world-66d45dfbcd-fk2rp
  Normal  SuccessfulCreate  6m14s  replicaset-controller  Created pod: hello-world-66d45dfbcd-lcgrq
  Normal  SuccessfulCreate  6m14s  replicaset-controller  Created pod: hello-world-66d45dfbcd-wwhzl
  Normal  SuccessfulCreate  6m14s  replicaset-controller  Created pod: hello-world-66d45dfbcd-nvb85
  Normal  SuccessfulCreate  6m4s   replicaset-controller  Created pod: hello-world-66d45dfbcd-n42m9
  Normal  SuccessfulCreate  6m4s   replicaset-controller  Created pod: hello-world-66d45dfbcd-5ltp7
  Normal  SuccessfulCreate  6m4s   replicaset-controller  Created pod: hello-world-66d45dfbcd-kcclj
  Normal  SuccessfulCreate  6m3s   replicaset-controller  Created pod: hello-world-66d45dfbcd-pjqch
  Normal  SuccessfulCreate  6m3s   replicaset-controller  (combined from similar events): Created pod: hello-world-66d45dfbcd-t4pcm
```

- The `OldReplicaSet`, check out labels, replicas, status and pod-template-hash
```
kubectl describe replicaset hello-world-6d59dfc665

Name:           hello-world-6d59dfc665
Namespace:      default
Selector:       app=hello-world,pod-template-hash=6d59dfc665
Labels:         app=hello-world
                pod-template-hash=6d59dfc665
Annotations:    deployment.kubernetes.io/desired-replicas: 10
                deployment.kubernetes.io/max-replicas: 13
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/hello-world
Replicas:       0 current / 0 desired
Pods Status:    0 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world
           pod-template-hash=6d59dfc665
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
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-kfk42
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-jhrlz
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-vrbkt
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-xh792
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-z2n7s
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-4gwc6
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-mlskh
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-pcs5r
  Normal  SuccessfulCreate  11m    replicaset-controller  Created pod: hello-world-6d59dfc665-srlzw
  Normal  SuccessfulCreate  11m    replicaset-controller  (combined from similar events): Created pod: hello-world-6d59dfc665-whd5q
  Normal  SuccessfulDelete  7m19s  replicaset-controller  Deleted pod: hello-world-6d59dfc665-z2n7s
  Normal  SuccessfulDelete  7m19s  replicaset-controller  Deleted pod: hello-world-6d59dfc665-4gwc6
  Normal  SuccessfulDelete  7m9s   replicaset-controller  Deleted pod: hello-world-6d59dfc665-pcs5r
  Normal  SuccessfulDelete  7m9s   replicaset-controller  Deleted pod: hello-world-6d59dfc665-srlzw
  Normal  SuccessfulDelete  7m9s   replicaset-controller  Deleted pod: hello-world-6d59dfc665-whd5q
  Normal  SuccessfulDelete  7m8s   replicaset-controller  Deleted pod: hello-world-6d59dfc665-xh792
  Normal  SuccessfulDelete  7m8s   replicaset-controller  Deleted pod: hello-world-6d59dfc665-vrbkt
  Normal  SuccessfulDelete  7m8s   replicaset-controller  Deleted pod: hello-world-6d59dfc665-kfk42
  Normal  SuccessfulDelete  7m8s   replicaset-controller  Deleted pod: hello-world-6d59dfc665-mlskh
  Normal  SuccessfulDelete  7m7s   replicaset-controller  (combined from similar events): Deleted pod: hello-world-6d59dfc665-jhrlz
```