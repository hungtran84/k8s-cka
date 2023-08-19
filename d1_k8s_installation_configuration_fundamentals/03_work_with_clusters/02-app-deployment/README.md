## Application Deployment

- Deploying resources imperatively in your cluster. This is pulling a simple hello-world app container image from a container registry.
```
kubectl create deployment hello-world --image=ghcr.io/hungtran84/hello-app:1.0

deployment.apps/hello-world created
```

- But let's deploy a single "bare" pod that's not managed by a controller...
```
kubectl run hello-world-pod --image=ghcr.io/hungtran84/hello-app:1.0

pod/hello-world-pod created
```

- Let's see of the Deployment creates a single replica and also see if that bare pod is created. You should have two pods here...
    - the one managed by our controller has a the pod template hash in it's name and a unique identifier
    - the bare pod

```
kubectl get pods

NAME                                READY   STATUS    RESTARTS   AGE
hello-world-689f56667c-pxjg4        1/1     Running   0          45s
hello-world-pod                     1/1     Running   0          23s
```

```
kubectl get pods -o wide

NAME                                READY   STATUS    RESTARTS   AGE    IP                NODE         NOMINATED NODE   READINESS GATES
hello-world-689f56667c-pxjg4        1/1     Running   0          109s   192.168.233.194   kube-node2   <none>           <none>
hello-world-pod                     1/1     Running   0          87s    192.168.9.66      kube-node1   <none>           <none>
```

- Remember, k8s is a container orchestrator and it's starting up containers on Nodes. Open a second terminal and ssh into the node that hello-world pod is running on.

```
gcloud compute ssh kube-node1
```


- When containerd is your container runtime, use crictl to get a listing of the containers running. Check out this for more details https://kubernetes.io/docs/tasks/debug-application-cluster/crictl

```
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps

CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD
baf7ed017467f       7f20d355455ed       4 minutes ago       Running             hello-world-pod     0                   c11d1ac9bf131       hello-world-pod
8c9b54b1d6fa3       7843b22c2915e       42 hours ago        Running             calico-node         0                   478c0de56b994       calico-node-6slmv
20f6ce0ff49a2       556768f31eb1d       42 hours ago        Running             kube-proxy          0                   bed30710b2e62       kube-proxy-fnzq8
```


- Back on CP node, we can pull the logs from the container. Which is going to be anything written to stdout. Maybe something went wrong inside our app and our pod won't start. This is useful for troubleshooting.

```
kubectl logs hello-world-pod

2023/8/11 11:5:10 Server listening on port 8080
2023/8/11 11:5:10 Serving request: /
```

- Starting a process inside a container inside a pod.
We can use this to launch any process as long as the executable/binary is in the container.
Launch a shell into the container. Callout that this is on the *pod* network.

```
kubectl exec -it  hello-world-pod -- /bin/sh
/app # hostname
hello-world-pod
/app # ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
3: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1440 qdisc noqueue state UP qlen 1000
    link/ether d6:ce:ce:00:4c:8e brd ff:ff:ff:ff:ff:ff
    inet 192.168.9.66/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d4ce:ceff:fe00:4c8e/64 scope link 
       valid_lft forever preferred_lft forever
/app # exit
```

- Remember that first kubectl create deployment we executed, it created a deployment for us.
Let's look more closely at that deployment. 
Deployments are made of `ReplicaSets` and `ReplicaSets` create `Pods`!

```
kubectl get deployment hello-world

NAME          READY   UP-TO-DATE   AVAILABLE   AGE
hello-world   1/1     1            1           4h45m
```
```
kubectl get replicaset

NAME                          DESIRED   CURRENT   READY   AGE
hello-world-689f56667c        1         1         1       4h45m
```
```
kubectl get pods

NAME                                READY   STATUS    RESTARTS   AGE
hello-world-689f56667c-pxjg4        1/1     Running   0          4h46m
```

- Let's take a closer look at our Deployment and it's Pods: `Name`, `Replicas`, and `Events`. In `Events`, notice how the `ReplicaSet` is created by the deployment.
Deployments are made of ReplicaSets!

```
kubectl describe deployment hello-world | more

Name:                   hello-world
Namespace:              default
CreationTimestamp:      Fri, 11 Aug 2023 15:58:18 +0000
Labels:                 app=hello-world
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=hello-world
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=hello-world
  Containers:
   hello-app:
    Image:        ghcr.io/hungtran84/hello-app:1.0
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   hello-world-689f56667c (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  71s   deployment-controller  Scaled up replica set hello-world-689f56667c to 1
```

- The `ReplicaSet` creates the `Pods`. Check out `Name`, `Controlled By`, `Replicas`, `Pod Template`, and `Events`.
In `Events`, notice how the ReplicaSet create the `Pods`

```
kubectl describe replicaset hello-world | more

Name:           hello-world-689f56667c
Namespace:      default
Selector:       app=hello-world,pod-template-hash=689f56667c
Labels:         app=hello-world
                pod-template-hash=689f56667c
Annotations:    deployment.kubernetes.io/desired-replicas: 1
                deployment.kubernetes.io/max-replicas: 2
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/hello-world
Replicas:       1 current / 1 desired
Pods Status:    1 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=hello-world
           pod-template-hash=689f56667c
  Containers:
   hello-app:
    Image:        ghcr.io/hungtran84/hello-app:1.0
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age   From                   Message
  ----    ------            ----  ----                   -------
  Normal  SuccessfulCreate  17s   replicaset-controller  Created pod: hello-world-689f56667c-fk7vv
```

- Check out the `Name`, `Node`, `Status`, `Controlled By`, `IPs`, `Containers`, and `Events`.
In `Events`, notice how the `Pod` is scheduled, the container image is pulled, and then the container is created and then started.

```
kubectl describe pod hello-world-689f56667c-fk7vv  | more

Name:             hello-world-689f56667c-fk7vv
Namespace:        default
Priority:         0
Service Account:  default
Node:             kube-node2/10.148.0.4
Start Time:       Fri, 11 Aug 2023 15:58:18 +0000
Labels:           app=hello-world
                  pod-template-hash=689f56667c
Annotations:      cni.projectcalico.org/containerID: 29dbaa4e0fbb11120bc643de2c23afe1507f456de33b5095d60f0a906e5de271
                  cni.projectcalico.org/podIP: 192.168.233.195/32
                  cni.projectcalico.org/podIPs: 192.168.233.195/32
Status:           Running
IP:               192.168.233.195
IPs:
  IP:           192.168.233.195
Controlled By:  ReplicaSet/hello-world-689f56667c
Containers:
  hello-app:
    Container ID:   containerd://179fb282ca458243004dc068a233db45cd6301fd790501e4f41e7bbaa6dd0248
    Image:          ghcr.io/hungtran84/hello-app:1.0
    Image ID:       ghcr.io/hungtran84/hello-app@sha256:a3af38fd5a7dbfe9328f71b00d04516e8e9c778b4886e8aaac8d9e8862a09bc7
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Fri, 11 Aug 2023 15:58:19 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-9tjg5 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-9tjg5:
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
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  3m15s  default-scheduler  Successfully assigned default/hello-world-689f56667c-fk7vv to kube-node
2
  Normal  Pulled     3m14s  kubelet            Container image "ghcr.io/hungtran84/hello-app:1.0" already present on mac
hine
  Normal  Created    3m14s  kubelet            Created container hello-app
  Normal  Started    3m14s  kubelet            Started container hello-app
```

- Expose the `Deployment` as a `Service`. This will create a `Service` for the `Deployment`
We are exposing our `Service` on port `80`, connecting to an application running on `8080` in our pod.
     - Port: Internal Cluster Port, the Service's port. You will point cluster resources here.
     - TargetPort: The Pod's Service Port, your application. That one we defined when we started the pods.
```
kubectl expose deployment hello-world --port=80 --target-port=8080

service/hello-world exposed
```

- Check out the `CLUSTER-IP` and `PORT(S)`, that's where we'll access this service, from inside the cluster.
```
kubectl get service hello-world

NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
hello-world   ClusterIP   10.103.123.115   <none>        80/TCP    44s
```

- We can also get that information from using describe. 
`Endpoints` are IP:Port pairs for each of Pods that that are a member of the Service.
Right now there is only one, later we'll increase the number of replicas and more `Endpoints` will be added.

```
kubectl describe service hello-world

Name:              hello-world
Namespace:         default
Labels:            app=hello-world
Annotations:       <none>
Selector:          app=hello-world
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.103.123.115
IPs:               10.103.123.115
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         192.168.233.195:8080
Session Affinity:  None
Events:            <none>
```

- Access the Service inside the cluster...

```
kubectl run mycurlpod --image=curlimages/curl -it --rm -- sh

If you don't see a command prompt, try pressing enter.
~ $ curl http://10.109.168.231
Hello, world!
Version: 1.0.0
hello-world-6bc984989-gd6kf
~ $ curl http://hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-gd6kf

~ $ cat /etc/resolv.conf 
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

```

- Let find out IP address of `10.96.0.10` belongs to...

```
kubectl get svc -n kube-system -owide
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE     SELECTOR
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   9m17s   k8s-app=kube-dns
```

- Access a single pod's application directly, useful for troubleshooting.

```
kubectl get endpoints hello-world

NAME          ENDPOINTS       AGE
hello-world   10.5.2.2:8080   6m56s
```

```
kubectl run mycurlpod --image=curlimages/curl -it --rm -- sh
If you don't see a command prompt, try pressing enter.
~ $ curl 10.5.2.2:8080
Hello, world!
Version: 1.0.0
hello-world-6bc984989-gd6kf
```

- Using kubectl to generate yaml or json for your deployments.
This includes runtime information which can be useful for monitoring and config management but not as source mainifests for declarative deployments


```
kubectl get deployment hello-world -o yaml | more 

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2023-08-11T16:23:40Z"
  generation: 1
  labels:
    app: hello-world
  name: hello-world
  namespace: default
  resourceVersion: "799"
  uid: 07117d48-7e04-4fef-bd32-b55a38760300
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: hello-world
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-world
    spec:
      containers:
      - image: ghcr.io/hungtran84/hello-app:1.0
        imagePullPolicy: IfNotPresent
        name: hello-app
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
status:
  availableReplicas: 1
  conditions:
  - lastTransitionTime: "2023-08-11T16:23:44Z"
    lastUpdateTime: "2023-08-11T16:23:44Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
...
```

```
kubectl get deployment hello-world -o json | more 

{
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "annotations": {
            "deployment.kubernetes.io/revision": "1"
        },
        "creationTimestamp": "2023-08-11T16:23:40Z",
        "generation": 1,
        "labels": {
            "app": "hello-world"
        },
        "name": "hello-world",
        "namespace": "default",
        "resourceVersion": "799",
        "uid": "07117d48-7e04-4fef-bd32-b55a38760300"
    },
    "spec": {
        "progressDeadlineSeconds": 600,
        "replicas": 1,
        "revisionHistoryLimit": 10,
        "selector": {
            "matchLabels": {
                "app": "hello-world"
            }
        },
        "strategy": {
            "rollingUpdate": {
                "maxSurge": "25%",
                "maxUnavailable": "25%"
            },
            "type": "RollingUpdate"
        },
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "hello-world"
                }
            },
            "spec": {
                "containers": [
...
```

- Let's remove everything we created imperatively and start over using a declarative model.
Deleting the deployment will delete the replicaset and then the pods.
We have to delete the bare pod manually since it's not managed by a contorller. 

```
kubectl delete service hello-world
kubectl delete deployment hello-world
kubectl delete pod hello-world-pod
```

```
kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   16m
```

- Deploying resources declaratively in your cluster.
We can use apply to create our resources from yaml.
We could write the yaml by hand but we can use `dry-run=client` to build it for us
This can be used a a template for move complex deployments.

```
kubectl create deployment hello-world \
     --image=ghcr.io/hungtran84/hello-app:1.0 \
     --dry-run=client -o yaml | more 

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: hello-world
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-world
    spec:
      containers:
      - image: ghcr.io/hungtran84/hello-app:1.0
        name: hello-app
        resources: {}
status: {}
```

- Let's write this deployment yaml out to file

```
kubectl create deployment hello-world \
     --image=ghcr.io/hungtran84/hello-app:1.0 \
     --dry-run=client -o yaml > deployment.yaml
```

- Create the deployment declaratively in code

```
kubectl apply -f deployment.yaml

deployment.apps/hello-world created
```

- Generate the yaml for the service

```
kubectl expose deployment hello-world \
     --port=80 --target-port=8080 \
     --dry-run=client -o yaml | more

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: hello-world
  name: hello-world
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: hello-world
status:
  loadBalancer: {}
```

- Write the service yaml manifest to file

```
kubectl expose deployment hello-world \
     --port=80 --target-port=8080 \
     --dry-run=client -o yaml > service.yaml 
```

- Create the service declaratively

```
kubectl apply -f service.yaml
service/hello-world created
```

- Check out our current state, `Deployment`, `ReplicaSet`, `Pod` and a `Service`

```
kubectl get all

NAME                              READY   STATUS    RESTARTS   AGE
pod/hello-world-6bc984989-hsn47   1/1     Running   0          115s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   25m

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-world   1/1     1            1           115s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-world-6bc984989   1         1         1       115s
```

- Scale up our deployment in code

```
vi deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: hello-world
  name: hello-world
spec:
  replicas: 20 # change from 1 to 20
  selector:
    matchLabels:
      app: hello-world
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-world
    spec:
      containers:
      - image: ghcr.io/hungtran84/hello-app:1.0
        name: hello-app
        resources: {}
status: {}
```

- Update our configuration with apply to make that code to the desired state
```
kubectl apply -f deployment.yaml
```

- And check the current configuration of our deployment, you should see 20/20
```
kubectl get deployment hello-world

NAME          READY   UP-TO-DATE   AVAILABLE   AGE
hello-world   20/20   20           20          11m
```

```
kubectl get pods | more 

NAME                          READY   STATUS    RESTARTS   AGE
hello-world-6bc984989-5lk7l   1/1     Running   0          4m17s
hello-world-6bc984989-6b8zs   1/1     Running   0          4m17s
hello-world-6bc984989-6lg6p   1/1     Running   0          4m17s
hello-world-6bc984989-7l82b   1/1     Running   0          4m17s
hello-world-6bc984989-bz8dr   1/1     Running   0          4m17s
hello-world-6bc984989-dtpxd   1/1     Running   0          4m17s
hello-world-6bc984989-f9sjv   1/1     Running   0          4m17s
hello-world-6bc984989-gjgbp   1/1     Running   0          4m17s
hello-world-6bc984989-hfjcs   1/1     Running   0          4m17s
hello-world-6bc984989-hhkdv   1/1     Running   0          4m17s
hello-world-6bc984989-hsn47   1/1     Running   0          11m
hello-world-6bc984989-jp74s   1/1     Running   0          4m17s
hello-world-6bc984989-mb7tq   1/1     Running   0          4m17s
hello-world-6bc984989-pm8s8   1/1     Running   0          4m17s
hello-world-6bc984989-qsk79   1/1     Running   0          4m17s
hello-world-6bc984989-rw9r6   1/1     Running   0          4m17s
hello-world-6bc984989-tw7b6   1/1     Running   0          4m17s
hello-world-6bc984989-tzgl9   1/1     Running   0          4m17s
hello-world-6bc984989-vdwpc   1/1     Running   0          4m17s
hello-world-6bc984989-zzqjl   1/1     Running   0          4m17s
```


- Repeat the curl access to see the load balancing of the HTTP request

```
kubectl run mycurlpod --image=curlimages/curl -it --rm -- sh
If you don't see a command prompt, try pressing enter.
~ $ curl hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-pm8s8
~ $ curl hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-qsk79
~ $ curl hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-tw7b6
~ $ curl hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-6lg6p
~ $ curl hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-zzqjl
~ $ curl hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-7l82b
~ $ curl hello-world
Hello, world!
Version: 1.0.0
hello-world-6bc984989-dtpxd
...
```

- We can edit the resources "on the fly" with kubectl edit. But this isn't reflected in our yaml. 
Let's increase replica number from 20 to 30

```
kubectl edit deployment hello-world
```

- The deployment is scaled to 30 and we have 30 pods

```
kubectl get deployment hello-world
```

- You can also scale a deployment using scale

```
kubectl scale deployment hello-world --replicas=40
kubectl get deployment hello-world
```

- Let's clean up our deployment and remove everything
```
kubectl delete deployment hello-world
kubectl delete service hello-world
kubectl get all
```