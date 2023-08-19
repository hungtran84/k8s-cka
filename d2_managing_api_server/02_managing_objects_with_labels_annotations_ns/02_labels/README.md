- Create a collection of pods with labels assinged to each
```
more CreatePodsWithLabels.yaml

kubectl apply -f CreatePodsWithLabels.yaml
pod/nginx-pod-1 created
pod/nginx-pod-2 created
pod/nginx-pod-3 created
pod/nginx-pod-4 created
```
- Look at all the Pod labels in our cluster
```
kubectl get pods --show-labels

NAME          READY   STATUS    RESTARTS   AGE   LABELS
nginx-pod-1   1/1     Running   0          32s   app=MyWebApp,deployment=v1,tier=prod
nginx-pod-2   1/1     Running   0          32s   app=MyWebApp,deployment=v1.1,tier=prod
nginx-pod-3   1/1     Running   0          32s   app=MyWebApp,deployment=v1.1,tier=qa
nginx-pod-4   1/1     Running   0          32s   app=MyAdminApp,deployment=v1,tier=prod
```

- Look at one Pod's labels in our cluster
```
kubectl describe pod nginx-pod-1 | head

Name:             nginx-pod-1
Namespace:        default
Priority:         0
Service Account:  default
Node:             gke-gke-test-default-pool-03d0c6b2-sv8f/10.148.0.6
Start Time:       Sun, 13 Aug 2023 14:42:17 +0700
Labels:           app=MyWebApp
                  deployment=v1
                  tier=prod
Annotations:      <none>
```
- Query labels and selectors
```
kubectl get pods --selector tier=prod
NAME          READY   STATUS    RESTARTS   AGE
nginx-pod-1   1/1     Running   0          104s
nginx-pod-2   1/1     Running   0          104s
nginx-pod-4   1/1     Running   0          104s

kubectl get pods --selector tier=qa
NAME          READY   STATUS    RESTARTS   AGE
nginx-pod-3   1/1     Running   0          2m

kubectl get pods -l tier=prod
NAME          READY   STATUS    RESTARTS   AGE
nginx-pod-1   1/1     Running   0          2m26s
nginx-pod-2   1/1     Running   0          2m26s
nginx-pod-4   1/1     Running   0          2m26s

kubectl get pods -l tier=prod --show-labels
```

- Selector for multiple labels and adding on show-labels to see those labels in the output
```
kubectl get pods -l 'tier=prod,app=MyWebApp' --show-labels
NAME          READY   STATUS    RESTARTS   AGE     LABELS
nginx-pod-1   1/1     Running   0          3m56s   app=MyWebApp,deployment=v1,tier=prod
nginx-pod-2   1/1     Running   0          3m56s   app=MyWebApp,deployment=v1.1,tier=prod

kubectl get pods -l 'tier=prod,app!=MyWebApp' --show-labels
NAME          READY   STATUS    RESTARTS   AGE     LABELS
nginx-pod-4   1/1     Running   0          4m12s   app=MyAdminApp,deployment=v1,tier=prod

kubectl get pods -l 'tier in (prod,qa)'
NAME          READY   STATUS    RESTARTS   AGE
nginx-pod-1   1/1     Running   0          4m28s
nginx-pod-2   1/1     Running   0          4m28s
nginx-pod-3   1/1     Running   0          4m28s
nginx-pod-4   1/1     Running   0          4m28s

kubectl get pods -l 'tier notin (prod,qa)'
No resources found in default namespace.
```

- Output a particluar label in column format
```
kubectl get pods -L tier
NAME          READY   STATUS    RESTARTS   AGE     TIER
nginx-pod-1   1/1     Running   0          5m11s   prod
nginx-pod-2   1/1     Running   0          5m11s   prod
nginx-pod-3   1/1     Running   0          5m11s   qa
nginx-pod-4   1/1     Running   0          5m11s   prod

kubectl get pods -L tier,app
NAME          READY   STATUS    RESTARTS   AGE     TIER   APP
nginx-pod-1   1/1     Running   0          5m37s   prod   MyWebApp
nginx-pod-2   1/1     Running   0          5m37s   prod   MyWebApp
nginx-pod-3   1/1     Running   0          5m37s   qa     MyWebApp
nginx-pod-4   1/1     Running   0          5m37s   prod   MyAdminApp
```

- Edit an existing label
```
kubectl label pod nginx-pod-1 tier=non-prod --overwrite
pod/nginx-pod-1 labeled

kubectl get pod nginx-pod-1 --show-labels
NAME          READY   STATUS    RESTARTS   AGE     LABELS
nginx-pod-1   1/1     Running   0          6m29s   app=MyWebApp,deployment=v1,tier=non-prod
```

- Adding a new label
```
kubectl label pod nginx-pod-1 another=Label
pod/nginx-pod-1 labeled

kubectl get pod nginx-pod-1 --show-labels
NAME          READY   STATUS    RESTARTS   AGE    LABELS
nginx-pod-1   1/1     Running   0          7m9s   another=Label,app=MyWebApp,deployment=v1,tier=non-prod
```

- Removing an existing label
```
kubectl label pod nginx-pod-1 another-
pod/nginx-pod-1 unlabeled

kubectl get pod nginx-pod-1 --show-labels
NAME          READY   STATUS    RESTARTS   AGE     LABELS
nginx-pod-1   1/1     Running   0          7m45s   app=MyWebApp,deployment=v1,tier=non-prod
```

- Performing an operation on a collection of pods based on a label query
```
kubectl label pod --all tier=non-prod --overwrite
pod/nginx-pod-1 not labeled
pod/nginx-pod-2 labeled
pod/nginx-pod-3 labeled
pod/nginx-pod-4 labeled

kubectl get pod --show-labels
NAME          READY   STATUS    RESTARTS   AGE     LABELS
nginx-pod-1   1/1     Running   0          8m29s   app=MyWebApp,deployment=v1,tier=non-prod
nginx-pod-2   1/1     Running   0          8m29s   app=MyWebApp,deployment=v1.1,tier=non-prod
nginx-pod-3   1/1     Running   0          8m29s   app=MyWebApp,deployment=v1.1,tier=non-prod
nginx-pod-4   1/1     Running   0          8m29s   app=MyAdminApp,deployment=v1,tier=non-prod
```

- Delete all pods matching our non-prod label
```
kubectl delete pod -l tier=non-prod
pod "nginx-pod-1" deleted
pod "nginx-pod-2" deleted
pod "nginx-pod-3" deleted
pod "nginx-pod-4" deleted
```
- And we're left with nothing.
```
kubectl get pods --show-labels
No resources found in default namespace.
```

- Kubernetes Resource Management
Start a Deployment with 3 replicas
```
kubectl apply -f deployment-label.yaml
deployment.apps/hello-world created
```

- Expose our `Deployment` as  `Service`
```
kubectl apply -f service.yaml
service/hello-world created
```

- Look at the `Labels` and `Selectors` on each resource, the `Deployment`, `ReplicaSet` and `Pod`
The deployment has a selector for `app=hello-world`
```
kubectl describe deployment hello-world

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Sun, 13 Aug 2023 14:52:28 +0700
Labels:                 app=hello-world
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=hello-world
Replicas:               4 desired | 4 updated | 4 total | 4 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=hello-world
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:1.0
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
NewReplicaSet:   hello-world-6d59dfc665 (4/4 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  88s   deployment-controller  Scaled up replica set hello-world-6d59dfc665 to 4
```

- The `ReplicaSet` has labels and selectors for app and the current pod-template-hash
Look at the `Pod Template` and the labels on the Pods created
```
kubectl describe replicaset hello-world

Name:           hello-world-6d59dfc665
Namespace:      default
Selector:       app=hello-world,pod-template-hash=6d59dfc665
Labels:         app=hello-world
                pod-template-hash=6d59dfc665
Annotations:    deployment.kubernetes.io/desired-replicas: 4
                deployment.kubernetes.io/max-replicas: 5
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/hello-world
Replicas:       4 current / 4 desired
Pods Status:    4 Running / 0 Waiting / 0 Succeeded / 0 Failed
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
  Type    Reason            Age   From                   Message
  ----    ------            ----  ----                   -------
  Normal  SuccessfulCreate  2m8s  replicaset-controller  Created pod: hello-world-6d59dfc665-k8lth
  Normal  SuccessfulCreate  2m8s  replicaset-controller  Created pod: hello-world-6d59dfc665-tx8g2
  Normal  SuccessfulCreate  2m8s  replicaset-controller  Created pod: hello-world-6d59dfc665-rcr2r
  Normal  SuccessfulCreate  2m8s  replicaset-controller  Created pod: hello-world-6d59dfc665-pmjmc
```
- The Pods have labels for `app=hello-world` and for the `pod-temlpate-hash` of the current `ReplicaSet`
```
kubectl get pods --show-labels

NAME                           READY   STATUS    RESTARTS   AGE     LABELS
hello-world-6d59dfc665-k8lth   1/1     Running   0          3m21s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-pmjmc   1/1     Running   0          3m21s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-rcr2r   1/1     Running   0          3m21s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-tx8g2   1/1     Running   0          3m21s   app=hello-world,pod-template-hash=6d59dfc665
```
- Edit the label on one of the Pods in the `ReplicaSet`, change the `pod-template-hash`
```
kubectl label pod hello-world-6d59dfc665-k8lth pod-template-hash=DEBUG --overwrite
pod/hello-world-6d59dfc665-k8lth labeled
```

- The ReplicaSet will deploy a new Pod to satisfy the number of replicas. Our relabeled Pod still exists.
```
kubectl get pods --show-labels

NAME                           READY   STATUS    RESTARTS   AGE     LABELS
hello-world-6d59dfc665-k8lth   1/1     Running   0          4m48s   app=hello-world,pod-template-hash=DEBUG
hello-world-6d59dfc665-pmjmc   1/1     Running   0          4m48s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-rcr2r   1/1     Running   0          4m48s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-rk729   1/1     Running   0          28s     app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-tx8g2   1/1     Running   0          4m48s   app=hello-world,pod-template-hash=6d59dfc665
```
- Let's look at how `Services` use `labels` and `selectors`, check out services.yaml
```
kubectl get service

NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
hello-world   ClusterIP   10.32.6.179   <none>        80/TCP    4m40s
kubernetes    ClusterIP   10.32.0.1     <none>        443/TCP   15h
```

- The `selector` for this serivce is `app=hello-world`, that pod is still being load balanced to!
```
kubectl describe service hello-world 
Name:              hello-world
Namespace:         default
Labels:            <none>
Annotations:       cloud.google.com/neg: {"ingress":true}
Selector:          app=hello-world
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.32.6.179
IPs:               10.32.6.179
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         10.28.0.15:8080,10.28.0.16:8080,10.28.0.17:8080 + 2 more...
Session Affinity:  None
Events:            <none>
```

- Get a list of all IPs in the service, there's 5,why?
```
kubectl describe endpoints hello-world
Name:         hello-world
Namespace:    default
Labels:       <none>
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2023-08-13T07:56:49Z
Subsets:
  Addresses:          10.28.0.15,10.28.0.16,10.28.0.17,10.28.1.9,10.28.2.16
  NotReadyAddresses:  <none>
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    <unset>  8080  TCP

Events:  <none>
```

- Get a list of pods and their IPs
```
kubectl get pod -o wide

NAME                           READY   STATUS    RESTARTS   AGE     IP           NODE                                      NOMINATED NODE   READINESS GATES
hello-world-6d59dfc665-k8lth   1/1     Running   0          7m19s   10.28.0.15   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-6d59dfc665-pmjmc   1/1     Running   0          7m19s   10.28.0.16   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-6d59dfc665-rcr2r   1/1     Running   0          7m19s   10.28.2.16   gke-gke-test-default-pool-03d0c6b2-bfk0   <none>           <none>
hello-world-6d59dfc665-rk729   1/1     Running   0          2m59s   10.28.0.17   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
hello-world-6d59dfc665-tx8g2   1/1     Running   0          7m19s   10.28.1.9    gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
```

- To remove a pod from load balancing, change the label used by the service's selector.
The ReplicaSet will respond by placing another pod in the ReplicaSet
```
kubectl get pods --show-labels
NAME                           READY   STATUS    RESTARTS   AGE     LABELS
hello-world-6d59dfc665-k8lth   1/1     Running   0          7m47s   app=hello-world,pod-template-hash=DEBUG
hello-world-6d59dfc665-pmjmc   1/1     Running   0          7m47s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-rcr2r   1/1     Running   0          7m47s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-rk729   1/1     Running   0          3m27s   app=hello-world,pod-template-hash=6d59dfc665
hello-world-6d59dfc665-tx8g2   1/1     Running   0          7m47s   app=hello-world,pod-template-hash=6d59dfc665

kubectl label pod hello-world-6d59dfc665-k8lth app=DEBUG --overwrite
pod/hello-world-6d59dfc665-k8lth labeled
```

- Look at the registered endpoint addresses. Now there's 4
```
kubectl describe endpoints hello-world
```

- To clean up, delete the deployment, service and the Pod removed from the replicaset
```
kubectl delete deployment hello-world
kubectl delete service hello-world
kubectl delete pod hello-world-6d59dfc665-k8lth
```

- Scheduling a pod to a node
Scheduling is a much deeper topic, we're focusing on how labels can be used to influence it here.
```
kubectl get nodes --show-labels
```

- Label our nodes with something descriptive
```
kubectl label node <node1> disk=local_ssd
kubectl label node <node2> hardware=local_gpu
```
- Query our labels to confirm.
```
kubectl get node -L disk,hardware

NAME                                      STATUS   ROLES    AGE   VERSION           DISK        HARDWARE
gke-gke-test-default-pool-03d0c6b2-bfk0   Ready    <none>   15h   v1.27.3-gke.100   local_ssd   
gke-gke-test-default-pool-03d0c6b2-n7l2   Ready    <none>   15h   v1.27.3-gke.100               local_gpu
gke-gke-test-default-pool-03d0c6b2-sv8f   Ready    <none>   15h   v1.27.3-gke.100               
```

- Create three Pods, two using nodeSelector, one without.
```
cat PodsToNodes.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-ssd
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
  nodeSelector:
    disk: local_ssd
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-gpu
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
  nodeSelector:
    hardware: local_gpu
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```
```
kubectl apply -f PodsToNodes.yaml
pod/nginx-pod-ssd created
pod/nginx-pod-gpu created
pod/nginx-pod created
```

- View the scheduling of the pods in the cluster.
```
kubectl get node -L disk,hardware
NAME                                      STATUS   ROLES    AGE   VERSION           DISK        HARDWARE
gke-gke-test-default-pool-03d0c6b2-bfk0   Ready    <none>   15h   v1.27.3-gke.100   local_ssd   
gke-gke-test-default-pool-03d0c6b2-n7l2   Ready    <none>   15h   v1.27.3-gke.100               local_gpu
gke-gke-test-default-pool-03d0c6b2-sv8f   Ready    <none>   15h   v1.27.3-gke.100               

kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP           NODE                                      NOMINATED NODE   READINESS GATES
hello-world-6d59dfc665-k8lth   1/1     Running   0          20m   10.28.0.15   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
nginx-pod                      1/1     Running   0          39s   10.28.0.18   gke-gke-test-default-pool-03d0c6b2-sv8f   <none>           <none>
nginx-pod-gpu                  1/1     Running   0          39s   10.28.1.10   gke-gke-test-default-pool-03d0c6b2-n7l2   <none>           <none>
nginx-pod-ssd                  1/1     Running   0          40s   10.28.2.17   gke-gke-test-default-pool-03d0c6b2-bfk0   <none>           <none>
```

- Clean up when we're finished, delete our labels and Pods
```
kubectl label node <node1> disk-
kubectl label node <node2> hardware-
kubectl delete pod nginx-pod
kubectl delete pod nginx-pod-gpu
kubectl delete pod nginx-pod-ssd
```
