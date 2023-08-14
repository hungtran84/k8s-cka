## Multi-container pods

- Review the code for a multi-container pod, the volume `webcontent` is an `emptyDir`, essentially a temporary file system.
This is mounted in the containers at `mountPath`, in two different locations inside the container.
As `producer` writes data, `consumer` can see it immediatly since it's a shared file system.

```yaml
# multicontainer-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multicontainer-pod
spec:
  containers:
  - name: producer
    image: ubuntu
    command: ["/bin/bash"]
    args: ["-c", "while true; do echo $(hostname) $(date) >> /var/log/index.html; sleep 10; done"]
    volumeMounts:
    - name: webcontent
      mountPath: /var/log
  - name: consumer
    image: nginx
    ports:
      - containerPort: 80
    volumeMounts:
    - name: webcontent
      mountPath: /usr/share/nginx/html
  volumes:
  - name: webcontent 
    emptyDir: {}
```

- Let's create our multi-container Pod.
```
kubectl apply -f multicontainer-pod.yaml
pod/multicontainer-pod created
```

- Let's connect to our Pod (not specifying a name defaults to the first container in the configuration)
```
kubectl exec -it multicontainer-pod -- /bin/sh

Defaulted container "producer" out of: producer, consumer
# ls -la /var/log
total 4
drwxrwxrwx  2 root root  24 Aug 14 05:35 .
drwxr-xr-x 11 root root 139 Jun 24 02:06 ..
-rw-r--r--  1 root root 480 Aug 14 05:37 index.html
# tail /var/log/index.html
multicontainer-pod Mon Aug 14 05:35:40 UTC 2023
multicontainer-pod Mon Aug 14 05:35:50 UTC 2023
multicontainer-pod Mon Aug 14 05:36:00 UTC 2023
multicontainer-pod Mon Aug 14 05:36:10 UTC 2023
multicontainer-pod Mon Aug 14 05:36:20 UTC 2023
multicontainer-pod Mon Aug 14 05:36:30 UTC 2023
multicontainer-pod Mon Aug 14 05:36:40 UTC 2023
multicontainer-pod Mon Aug 14 05:36:50 UTC 2023
multicontainer-pod Mon Aug 14 05:37:00 UTC 2023
multicontainer-pod Mon Aug 14 05:37:10 UTC 2023
# exit
```

- Let's specify a container name and access the `consumer` container in our Pod.
```
kubectl exec -it multicontainer-pod --container consumer -- /bin/sh

# ls -la /usr/share/nginx/html
total 4
drwxrwxrwx 2 root root  24 Aug 14 05:35 .
drwxr-xr-x 3 root root  18 Jul 28 02:30 ..
-rw-r--r-- 1 root root 960 Aug 14 05:38 index.html
# tail /usr/share/nginx/html/index.html
multicontainer-pod Mon Aug 14 05:37:20 UTC 2023
multicontainer-pod Mon Aug 14 05:37:30 UTC 2023
multicontainer-pod Mon Aug 14 05:37:40 UTC 2023
multicontainer-pod Mon Aug 14 05:37:50 UTC 2023
multicontainer-pod Mon Aug 14 05:38:00 UTC 2023
multicontainer-pod Mon Aug 14 05:38:10 UTC 2023
multicontainer-pod Mon Aug 14 05:38:20 UTC 2023
multicontainer-pod Mon Aug 14 05:38:30 UTC 2023
multicontainer-pod Mon Aug 14 05:38:40 UTC 2023
multicontainer-pod Mon Aug 14 05:38:50 UTC 2023
# exit
```

- This application listens on port 80, we'll forward from 8080->80
```
kubectl port-forward multicontainer-pod 8080:80 &

curl http://localhost:8080
Handling connection for 8080
multicontainer-pod Mon Aug 14 05:35:40 UTC 2023
multicontainer-pod Mon Aug 14 05:35:50 UTC 2023
multicontainer-pod Mon Aug 14 05:36:00 UTC 2023
multicontainer-pod Mon Aug 14 05:36:10 UTC 2023
multicontainer-pod Mon Aug 14 05:36:20 UTC 2023
multicontainer-pod Mon Aug 14 05:36:30 UTC 2023
multicontainer-pod Mon Aug 14 05:36:40 UTC 2023
multicontainer-pod Mon Aug 14 05:36:50 UTC 2023
multicontainer-pod Mon Aug 14 05:37:00 UTC 2023
multicontainer-pod Mon Aug 14 05:37:10 UTC 2023
multicontainer-pod Mon Aug 14 05:37:20 UTC 2023
multicontainer-pod Mon Aug 14 05:37:30 UTC 2023
multicontainer-pod Mon Aug 14 05:37:40 UTC 2023
multicontainer-pod Mon Aug 14 05:37:50 UTC 2023
multicontainer-pod Mon Aug 14 05:38:00 UTC 2023
multicontainer-pod Mon Aug 14 05:38:10 UTC 2023
multicontainer-pod Mon Aug 14 05:38:20 UTC 2023
multicontainer-pod Mon Aug 14 05:38:30 UTC 2023
multicontainer-pod Mon Aug 14 05:38:40 UTC 2023
multicontainer-pod Mon Aug 14 05:38:50 UTC 2023
multicontainer-pod Mon Aug 14 05:39:00 UTC 2023
multicontainer-pod Mon Aug 14 05:39:10 UTC 2023
multicontainer-pod Mon Aug 14 05:39:20 UTC 2023
multicontainer-pod Mon Aug 14 05:39:30 UTC 2023
multicontainer-pod Mon Aug 14 05:39:40 UTC 2023
multicontainer-pod Mon Aug 14 05:39:50 UTC 2023
```

- Kill our port-forward.
```
fg
ctrl+c
```
- Cleanup resources

```
kubectl delete pod multicontainer-pod
```