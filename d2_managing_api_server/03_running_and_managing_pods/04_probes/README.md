## Implement container probes

- Start a watch to see the events associated with our probes.
```
kubectl get events --watch &
clear
```
- We have a single container pod app, in a `Deployment` that has both a `liveness` probe and a `readiness` probe

```yaml
# more container-probes.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: ghcr.io/hungtran84/hello-app:1.0
        ports:
        - containerPort: 8080
        livenessProbe:
          tcpSocket:
            port: 8081
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8081
          initialDelaySeconds: 10
          periodSeconds: 5
```

- Send in our deployment, after 10 seconds, our liveness and readiness probes will fail.
The liveness probe will kill the current pod, and recreate one.
```
kubectl apply -f container-probes.yaml

deployment.apps/hello-world created
0s          Normal   ScalingReplicaSet   deployment/hello-world          Scaled up replica set hello-world-cfd766b9c to 1
0s          Normal   SuccessfulCreate    replicaset/hello-world-cfd766b9c   Created pod: hello-world-cfd766b9c-gn6pb
0s          Normal   Scheduled           pod/hello-world-cfd766b9c-gn6pb    Successfully assigned default/hello-world-cfd766b9c-gn6pb to node3
0s          Normal   Pulling             pod/hello-world-cfd766b9c-gn6pb    Pulling image "ghcr.io/hungtran84/hello-app:1.0"
0s          Normal   Pulled              pod/hello-world-cfd766b9c-gn6pb    Successfully pulled image "ghcr.io/hungtran84/hello-app:1.0" in 3.748989077s (3.749030279s including waiting)
0s          Normal   Created             pod/hello-world-cfd766b9c-gn6pb    Created container hello-world
0s          Normal   Started             pod/hello-world-cfd766b9c-gn6pb    Started container hello-world
0s          Warning   Unhealthy           pod/hello-world-cfd766b9c-gn6pb    Readiness probe failed: Get "http://10.5.2.2:8081/": dial tcp 10.5.2.2:8081: connect: connection refused
0s          Warning   Unhealthy           pod/hello-world-cfd766b9c-gn6pb    Liveness probe failed: dial tcp 10.5.2.2:8081: connect: connection refused
...
```
- kill our watch
```
fg
ctrl+c
```

- We can see that our container isn't ready 0/1 and it's Restarts are increasing.
```
kubectl get pods
NAME                          READY   STATUS             RESTARTS     AGE
hello-world-cfd766b9c-gn6pb   0/1     CrashLoopBackOff   4 (7s ago)   112s
```

- Let's figure out what's wrong
```
kubectl describe pods
```
  - 1. We can see in the events. The `Liveness` and `Readiness` probe failures.
    ```
    Events:
      Type     Reason     Age                    From               Message
      ----     ------     ----                   ----               -------
      Normal   Scheduled  3m44s                  default-scheduler  Successfully assigned default/hello-world-cfd766b9c-gn6pb to node3
      Normal   Pulling    3m44s                  kubelet            Pulling image "ghcr.io/hungtran84/hello-app:1.0"
      Normal   Pulled     3m40s                  kubelet            Successfully pulled image "ghcr.io/hungtran84/hello-app:1.0" in 3.748989077s (3.749030279s including waiting)
      Normal   Started    3m19s (x2 over 3m40s)  kubelet            Started container hello-world
      Normal   Created    2m59s (x3 over 3m40s)  kubelet            Created container hello-world
      Warning  Unhealthy  2m59s (x8 over 3m29s)  kubelet            Readiness probe failed: Get "http://10.5.2.2:8081/": dial tcp 10.5.2.2:8081: connect: connection refused
      Warning  Unhealthy  2m59s (x6 over 3m29s)  kubelet            Liveness probe failed: dial tcp 10.5.2.2:8081: connect: connection refused
      Normal   Killing    2m59s (x2 over 3m19s)  kubelet            Container hello-world failed liveness probe, will be restarted
      Normal   Pulled     2m59s (x2 over 3m19s)  kubelet            Container image "ghcr.io/hungtran84/hello-app:1.0" already present on machine
    ```

  - 2. Under `Containers`, `Liveness` and `Readiness`, we can see the current configuration. And the current probe configuration. Both are pointing to `8081`.
    ```
    Liveness:       tcp-socket :8081 delay=10s timeout=1s period=5s #success=1 #failure=3
    Readiness:      http-get http://:8081/ delay=10s timeout=1s period=5s #success=1 #failure=3
    ```

  - 3. Under Containers, Ready and Container Contidtions, we can see that the container isn't ready.
    ```
    Conditions:
    Type              Status
    Initialized       True 
    Ready             False 
    ContainersReady   False 
    PodScheduled      True 
    ```
  4. Our Container Port is 8080, that's what we want our probes, probings. 

- So let's go ahead and change the probes to 8080
```yaml
# vi container-probes.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: ghcr.io/hungtran84/hello-app:1.0
        ports:
        - containerPort: 8080
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
```

- And send that change into the API Server for this deployment.
```
kubectl apply -f container-probes.yaml
deployment.apps/hello-world configured
```
- Confirm our probes are pointing to the correct container port now, which is `8080`.
```
kubectl describe pods
...
    Liveness:       tcp-socket :8080 delay=10s timeout=1s period=5s #success=1 #failure=3
    Readiness:      http-get http://:8080/ delay=10s timeout=1s period=5s #success=1 #failure=3
...
```
- Let's check our status, a couple of things happened there.
  - 1. Our `Deployment ReplicaSet` created a NEW Pod, when we pushed in the new deployment configuration.
  - 2. It's not immediately ready because of our `initialDelaySeconds` which is 10 seconds.
  - 3. If we wait long enough, the `livenessProbe` will kill the original Pod and it will go away.
  - 4. Leaving us with the one pod in our Deployment's ReplicaSet
```
kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-7fbf97c75f-8fpdf   1/1     Running   0          2m33s
```

- Cleanup things
```
kubectl delete deployment hello-world
```

- Let's start up a watch on kubectl get events
```
kubectl get events --watch &
clear
```

- Create our deployment with a faulty startup probe.
```yaml
# more container-probes-startup.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: ghcr.io/hungtran84/hello-app:1.0
        ports:
        - containerPort: 8080
        startupProbe:
          tcpSocket:
            port: 8081
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 1
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
```
You'll see failures since the `startup probe` is looking for `8081`
but you won't see the liveness or readiness probes executed.
The container will be restarted after 1 failures, since `failureThreshold` defaults to 3, this can take up to 30 seconds.
The container restart policy default is `Always`, so it will restart.
```
kubectl apply -f container-probes-startup.yaml
```

- Do you see any container restarts?  You should see 1.
```
kubectl get pods
NAME                          READY   STATUS    RESTARTS     AGE
hello-world-bc5df79bf-9f8qj   0/1     Running   5 (4s ago)   109s
```

- Change the startup probe from 8081 to 8080
```
kubectl apply -f container-probes-startup.yaml
```

- Our pod should be up and Ready now.
```
kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-6d4d44d9d8-rlcsg   1/1     Running   0          19s
```
- Close our watch
```
fg
ctrl+c
```

- Cleanup time
```
kubectl delete -f container-probes-startup.yaml
```