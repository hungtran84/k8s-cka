## Creating a DaemonSet on All Nodes
- We get one `Pod` per `Node` to run network services on that Node
```
kubectl get nodes
NAME    STATUS   ROLES           AGE     VERSION
node1   Ready    control-plane   2m39s   v1.27.2
node2   Ready    <none>          2m11s   v1.27.2
node3   Ready    <none>          2m7s    v1.27.2
node4   Ready    <none>          2m5s    v1.27.2
node5   Ready    <none>          2m2s    v1.27.2

kubectl get daemonsets --namespace kube-system kube-proxy
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-proxy   5         5         5       5            5           kubernetes.io/os=linux   3m1s
```

- Let's create a DaemonSet with Pods on each node in our cluster
```
kubectl apply -f DaemonSet.yaml
daemonset.apps/hello-world-ds created
```

#o we'll get 4 since we have 4 workers and 1 Control Plane Node in our cluster and the Control Plane Node is set to run only system pods
```
kubectl get daemonsets
AME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
hello-world-ds   4         4         4       4            4           <none>          67s

kubectl get daemonsets -o wide
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE    CONTAINERS    IMAGES                                SELECTOR
hello-world-ds   4         4         4       4            4           <none>          116s   hello-world   ghcr.io/hungtran84/hello-app:1.0   app=hello-world-app

kubectl get pods -o wide
NAME                   READY   STATUS    RESTARTS   AGE     IP         NODE    NOMINATED NODE   READINESS GATES
hello-world-ds-65z6k   1/1     Running   0          2m39s   10.5.2.3   node3   <none>           <none>
hello-world-ds-bbxtj   1/1     Running   0          2m39s   10.5.4.3   node5   <none>           <none>
hello-world-ds-wmt4q   1/1     Running   0          2m39s   10.5.3.6   node4   <none>           <none>
hello-world-ds-x6sht   1/1     Running   0          2m39s   10.5.1.3   node2   <none>           <none>
```

- Checks `Labels`, Desired/Current `Nodes Scheduled`. `Pod Status` and `Template` and `Events`.
```
kubectl describe daemonsets hello-world | more 
Name:           hello-world-ds
Selector:       app=hello-world-app
Node-Selector:  <none>
Labels:         <none>
Annotations:    deprecated.daemonset.template.generation: 1
Desired Number of Nodes Scheduled: 4
Current Number of Nodes Scheduled: 4
Number of Nodes Scheduled with Up-to-date Pods: 4
Number of Nodes Scheduled with Available Pods: 4
Number of Nodes Misscheduled: 0
Pods Status:  4 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world-app
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:1.0
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age    From                  Message
  ----    ------            ----   ----                  -------
  Normal  SuccessfulCreate  3m25s  daemonset-controller  Created pod: hello-world-ds-x6sht
  Normal  SuccessfulCreate  3m25s  daemonset-controller  Created pod: hello-world-ds-wmt4q
  Normal  SuccessfulCreate  3m25s  daemonset-controller  Created pod: hello-world-ds-65z6k
  Normal  SuccessfulCreate  3m25s  daemonset-controller  Created pod: hello-world-ds-bbxtj
```

- Each Pods is created with our label, `app=hello-world`, `controller-revision-hash` and a `pod-template-generation`
```
kubectl get pods --show-labels
AME                   READY   STATUS    RESTARTS   AGE     LABELS
hello-world-ds-65z6k   1/1     Running   0          5m24s   app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
hello-world-ds-bbxtj   1/1     Running   0          5m24s   app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
hello-world-ds-wmt4q   1/1     Running   0          5m24s   app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
hello-world-ds-x6sht   1/1     Running   0          5m24s   app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
```
- If we change the label to one of our Pods
```
MYPOD=$(kubectl get pods -l app=hello-world-app | grep hello-world | head -n 1 | awk {'print $1'})

echo $MYPOD
hello-world-ds-65z6k

kubectl label pods $MYPOD app=not-hello-world --overwrite
pod/hello-world-ds-65z6k labeled
```

- We'll get a new Pod from the DaemonSet Controller
```
kubectl get pods --show-labels
NAME                   READY   STATUS    RESTARTS   AGE     LABELS
hello-world-ds-65z6k   1/1     Running   0          7m41s   app=not-hello-world,controller-revision-hash=787b588d67,pod-template-generation=1
hello-world-ds-bbxtj   1/1     Running   0          7m41s   app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
hello-world-ds-k6tv5   1/1     Running   0          28s     app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
hello-world-ds-wmt4q   1/1     Running   0          7m41s   app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
hello-world-ds-x6sht   1/1     Running   0          7m41s   app=hello-world-app,controller-revision-hash=787b588d67,pod-template-generation=1
```
- Let's clean up this DaemonSet
```
kubectl delete daemonsets hello-world-ds
kubectl delete pods $MYPOD
```

## Creating a `DaemonSet` on a `Subset` of `Nodes`
- Let's create a DaemonSet with a defined `nodeSelector`
```
kubectl apply -f DaemonSetWithNodeSelector.yaml
daemonset.apps/hello-world-ds created
```

- No pods created because we don't have any nodes with the appropriate label
```
kubectl get daemonsets
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR         AGE
hello-world-ds   0         0         0       0            0           node=hello-world-ns   26s
```

- We need a Node that satisfies the `Node Selector`
```
kubectl label node node2 node=hello-world-ns
node/node2 labeled
```
- Let's see if a Pod gets created...
```
kubectl get daemonsets
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR         AGE
hello-world-ds   1         1         1       1            1           node=hello-world-ns   91s

kubectl get daemonsets -o wide
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR         AGE    CONTAINERS    IMAGES                                SELECTOR
hello-world-ds   1         1         1       1            1           node=hello-world-ns   115s   hello-world   ghcr.io/hungtran84/hello-app:1.0   app=hello-world-app

kubectl get pods -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP         NODE    NOMINATED NODE   READINESS GATES
hello-world-ds-59qwm   1/1     Running   0          64s   10.5.1.4   node2   <none>           <none>
```

- What's going to happen if we remove the label
```
kubectl label node node2 node-
node/node2 unlabeled
```

- It's going to terminate the Pod. 
Examine events, Desired Number of Nodes Scheduled
```
kubectl describe daemonsets hello-world-ds
Name:           hello-world-ds
Selector:       app=hello-world-app
Node-Selector:  node=hello-world-ns
Labels:         <none>
Annotations:    deprecated.daemonset.template.generation: 1
Desired Number of Nodes Scheduled: 0
Current Number of Nodes Scheduled: 0
Number of Nodes Scheduled with Up-to-date Pods: 0
Number of Nodes Scheduled with Available Pods: 0
Number of Nodes Misscheduled: 0
Pods Status:  0 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world-app
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:1.0
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age    From                  Message
  ----    ------            ----   ----                  -------
  Normal  SuccessfulCreate  2m44s  daemonset-controller  Created pod: hello-world-ds-59qwm
  Normal  SuccessfulDelete  39s    daemonset-controller  Deleted pod: hello-world-ds-59qwm
```

- Clean up our demo
```
kubectl delete daemonsets hello-world-ds
```

## Updating a DaemonSet
- Deploy our `v1` `DaemonSet` again
```
kubectl apply -f DaemonSet.yaml
```

- Check out our image version (it should be `1.0`)
```
kubectl describe daemonsets hello-world
```

- Examine what our update stategy, it is defaults to `rollingUpdate` and `maxUnavailable` 1
```
kubectl get DaemonSet hello-world-ds -o yaml | more

apiVersion: apps/v1
kind: DaemonSet
metadata:
  annotations:
    deprecated.daemonset.template.generation: "1"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"apps/v1","kind":"DaemonSet","metadata":{"annotations":{},"name":"hello-world-ds","namespace":"def
ault"},"spec":{"selector":{"matchLabels":{"app":"hello-world-app"}},"template":{"metadata":{"labels":{"app":"hello-wor
ld-app"}},"spec":{"containers":[{"image":"ghcr.io/hungtran84/hello-app:1.0","name":"hello-world"}]}}}}
  creationTimestamp: "2023-08-18T15:37:09Z"
  generation: 1
  name: hello-world-ds
  namespace: default
  resourceVersion: "3301"
  uid: e39ea27d-1561-4fdd-bc3b-2d21fe771376
spec:
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: hello-world-app
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-world-app
    spec:
      containers:
      - image: ghcr.io/hungtran84/hello-app:1.0
        imagePullPolicy: IfNotPresent
        name: hello-world
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
  updateStrategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
```

- Update our container image from 1.0 to 2.0 and apply the config
```
diff DaemonSet.yaml DaemonSet-v2.yaml
16,17c16
<           image: ghcr.io/hungtran84/hello-app:1.0
< 
---
>           image: ghcr.io/hungtran84/hello-app:2.0

kubectl apply -f DaemonSet-v2.yaml
daemonset.apps/hello-world-ds configured
```

- Check on the status of our rollout, a touch slower than a deployment due to maxUnavailable.
```
kubectl rollout status daemonsets hello-world-ds
daemon set "hello-world-ds" successfully rolled out
```

- We can see our `DaemonSet Container Image` is now `2.0` and in the `Events` that it rolled out.
```
kubectl describe daemonsets

Name:           hello-world-ds
Selector:       app=hello-world-app
Node-Selector:  <none>
Labels:         <none>
Annotations:    deprecated.daemonset.template.generation: 2
Desired Number of Nodes Scheduled: 4
Current Number of Nodes Scheduled: 4
Number of Nodes Scheduled with Up-to-date Pods: 4
Number of Nodes Scheduled with Available Pods: 4
Number of Nodes Misscheduled: 0
Pods Status:  4 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world-app
  Containers:
   hello-world:
    Image:        ghcr.io/hungtran84/hello-app:2.0
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age    From                  Message
  ----    ------            ----   ----                  -------
  Normal  SuccessfulCreate  3m54s  daemonset-controller  Created pod: hello-world-ds-nksld
  Normal  SuccessfulCreate  3m54s  daemonset-controller  Created pod: hello-world-ds-cdtdw
  Normal  SuccessfulCreate  3m54s  daemonset-controller  Created pod: hello-world-ds-vv4lp
  Normal  SuccessfulCreate  3m54s  daemonset-controller  Created pod: hello-world-ds-9g5v5
  Normal  SuccessfulDelete  69s    daemonset-controller  Deleted pod: hello-world-ds-nksld
  Normal  SuccessfulCreate  69s    daemonset-controller  Created pod: hello-world-ds-hz4bx
  Normal  SuccessfulDelete  65s    daemonset-controller  Deleted pod: hello-world-ds-cdtdw
  Normal  SuccessfulCreate  64s    daemonset-controller  Created pod: hello-world-ds-7j5jg
  Normal  SuccessfulDelete  62s    daemonset-controller  Deleted pod: hello-world-ds-9g5v5
  Normal  SuccessfulCreate  61s    daemonset-controller  Created pod: hello-world-ds-tdprd
  Normal  SuccessfulDelete  59s    daemonset-controller  Deleted pod: hello-world-ds-vv4lp
  Normal  SuccessfulCreate  58s    daemonset-controller  Created pod: hello-world-ds-6lp76
```

- We can see the new `controller-revision-hash` and also an updated `pod-template-generation`
```
kubectl get pods --show-labels
NAME                   READY   STATUS    RESTARTS   AGE    LABELS
hello-world-ds-6lp76   1/1     Running   0          112s   app=hello-world-app,controller-revision-hash=7bd8548fbd,pod-template-generation=2
hello-world-ds-7j5jg   1/1     Running   0          118s   app=hello-world-app,controller-revision-hash=7bd8548fbd,pod-template-generation=2
hello-world-ds-hz4bx   1/1     Running   0          2m3s   app=hello-world-app,controller-revision-hash=7bd8548fbd,pod-template-generation=2
hello-world-ds-tdprd   1/1     Running   0          115s   app=hello-world-app,controller-revision-hash=7bd8548fbd,pod-template-generation=2
```

- Time to clean up our resources
```
kubectl delete daemonsets hello-world-ds
```
